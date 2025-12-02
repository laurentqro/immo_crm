# frozen_string_literal: true

# XbrlGenerator creates XBRL XML documents from submission values.
# Follows the AMSF strix taxonomy format for Monaco AML/CFT reporting.
#
class XbrlGenerator
  # XBRL Namespaces
  XBRL_NS = "http://www.xbrl.org/2003/instance"
  LINK_NS = "http://www.xbrl.org/2003/linkbase"
  XLINK_NS = "http://www.w3.org/1999/xlink"
  ISO4217_NS = "http://www.xbrl.org/2003/iso4217"
  STRIX_NS = "http://amsf.mc/fr/taxonomy/strix"

  # Context IDs
  ENTITY_CONTEXT_ID = "ctx_entity"

  # Unit IDs
  EUR_UNIT_ID = "unit_EUR"
  PURE_UNIT_ID = "unit_pure"

  # Monetary element patterns (elements that need currency units)
  MONETARY_ELEMENTS = %w[
    a2104B a2105 a2106 a2107 a2202 a2302
  ].freeze

  attr_reader :submission, :organization

  def initialize(submission)
    @submission = submission
    @organization = submission.organization
  end

  # Generate complete XBRL XML document
  def generate
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.xbrl(xbrl_attributes) do
        build_schema_ref(xml)
        build_contexts(xml)
        build_units(xml)
        build_facts(xml)
      end
    end

    builder.to_xml
  end

  # Suggested filename for the XBRL file
  def suggested_filename
    "amsf_#{submission.year}_#{organization.rci_number}.xml"
  end

  private

  def xbrl_attributes
    {
      "xmlns" => XBRL_NS,
      "xmlns:link" => LINK_NS,
      "xmlns:xlink" => XLINK_NS,
      "xmlns:iso4217" => ISO4217_NS,
      "xmlns:strix" => STRIX_NS,
      "xmlns:xbrli" => XBRL_NS
    }
  end

  def build_schema_ref(xml)
    xml["link"].schemaRef(
      "xlink:type" => "simple",
      "xlink:href" => "http://amsf.mc/fr/taxonomy/strix/#{submission.taxonomy_version}/strix.xsd"
    )
  end

  def build_contexts(xml)
    # Main entity context
    xml.context_(:id => ENTITY_CONTEXT_ID) do
      xml.entity_ do
        xml.identifier_(:scheme => "http://amsf.mc/rci") do
          xml.text(organization.rci_number)
        end
      end
      xml.period_ do
        xml.instant_ do
          xml.text(Date.new(submission.year, 12, 31).iso8601)
        end
      end
    end

    # Build dimensional contexts for country breakdowns
    build_country_contexts(xml)
  end

  def build_country_contexts(xml)
    country_values = submission.submission_values.where("element_name LIKE ?", "a1103_%")

    country_values.find_each do |value|
      country_code = value.element_name.split("_").last
      next if country_code.blank?

      context_id = "ctx_country_#{country_code}"

      xml.context_(:id => context_id) do
        xml.entity_ do
          xml.identifier_(:scheme => "http://amsf.mc/rci") do
            xml.text(organization.rci_number)
          end
          xml.segment_ do
            xml["strix"].CountryDimension(country_code)
          end
        end
        xml.period_ do
          xml.instant_ do
            xml.text(Date.new(submission.year, 12, 31).iso8601)
          end
        end
      end
    end
  end

  def build_units(xml)
    # EUR currency unit for monetary values
    xml.unit_(:id => EUR_UNIT_ID) do
      xml["iso4217"].EUR
    end

    # Pure unit for counts and integers
    xml.unit_(:id => PURE_UNIT_ID) do
      xml["xbrli"].pure
    end
  end

  def build_facts(xml)
    submission.submission_values.find_each do |submission_value|
      build_fact(xml, submission_value)
    end
  end

  def build_fact(xml, submission_value)
    return if submission_value.value.blank?

    element_name = submission_value.element_name
    value = submission_value.value

    # Determine context and unit
    context_ref = context_for_element(element_name)
    unit_ref = unit_for_element(element_name)

    attributes = {
      contextRef: context_ref
    }
    attributes[:unitRef] = unit_ref if unit_ref
    attributes[:decimals] = "2" if monetary_element?(element_name)

    xml["strix"].send(element_name, format_value(value, element_name), attributes)
  end

  def context_for_element(element_name)
    # Country dimension elements use dimensional context
    if element_name.start_with?("a1103_")
      country_code = element_name.split("_").last
      "ctx_country_#{country_code}"
    else
      ENTITY_CONTEXT_ID
    end
  end

  def unit_for_element(element_name)
    if monetary_element?(element_name)
      EUR_UNIT_ID
    elsif numeric_element?(element_name)
      PURE_UNIT_ID
    end
  end

  def monetary_element?(element_name)
    MONETARY_ELEMENTS.include?(element_name)
  end

  def numeric_element?(element_name)
    # Most elements are numeric (counts or monetary)
    # Boolean elements typically contain "Policy" or specific patterns
    !boolean_element?(element_name)
  end

  def boolean_element?(element_name)
    # Policy elements (a4xxx series) are typically boolean
    element_name.start_with?("a4") && !monetary_element?(element_name)
  end

  def format_value(value, element_name)
    return value if value.blank?

    if boolean_element?(element_name)
      # Normalize boolean to lowercase
      value.to_s.downcase.in?(%w[true yes 1]) ? "true" : "false"
    elsif monetary_element?(element_name)
      # Format as decimal with 2 places
      format("%.2f", BigDecimal(value.to_s))
    else
      value.to_s
    end
  rescue ArgumentError
    value.to_s
  end
end
