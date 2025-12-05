# frozen_string_literal: true

module Xbrl
  # Raised when taxonomy files cannot be loaded or parsed
  class TaxonomyLoadError < StandardError
    attr_reader :file_path, :cause

    def initialize(message, file_path: nil, cause: nil)
      @file_path = file_path
      @cause = cause
      super(message)
    end
  end

  # Taxonomy parses AMSF XBRL taxonomy files and provides element metadata.
  # This is the single source of truth for element types, labels, and ordering.
  #
  # Usage:
  #   Xbrl::Taxonomy.element("a1101")       # => TaxonomyElement
  #   Xbrl::Taxonomy.elements               # => Array of all elements
  #   Xbrl::Taxonomy.elements_by_section    # => Hash grouped by section
  #
  class Taxonomy
    TAXONOMY_DIR = Rails.root.join("docs", "taxonomy")
    SCHEMA_FILE = "strix_Real_Estate_AML_CFT_survey_2025.xsd"
    LABEL_FILE = "strix_Real_Estate_AML_CFT_survey_2025_lab.xml"
    PRESENTATION_FILE = "strix_Real_Estate_AML_CFT_survey_2025_pre.xml"
    SHORT_LABELS_FILE = Rails.root.join("config", "xbrl_short_labels.yml")

    # XSD type mappings to Ruby symbols
    TYPE_MAPPINGS = {
      "xbrli:integerItemType" => :integer,
      "xbrli:monetaryItemType" => :monetary,
      "xbrli:stringItemType" => :string,
      "xbrli:pureItemType" => :decimal
    }.freeze

    # a1103 is the only dimensional element in the AMSF taxonomy.
    # It requires per-country breakdown using XBRL dimensional contexts.
    # This is hardcoded because the taxonomy definition files don't explicitly
    # mark dimensional elements in a parseable way.
    DIMENSIONAL_ELEMENTS = %w[a1103].freeze

    # Mutex for thread-safe taxonomy loading in multi-threaded servers (Puma)
    LOAD_MUTEX = Mutex.new

    class << self
      def element(name)
        elements_by_name[name]
      end

      def elements
        load_taxonomy
        @sorted_elements ||= @elements.values.sort_by(&:order).freeze
      end

      def elements_by_name
        load_taxonomy
        @elements
      end

      def elements_by_section
        elements.group_by(&:section)
      end

      # Manual short labels from config/xbrl_short_labels.yml
      def short_labels
        @short_labels ||= load_short_labels
      end

      def short_label_for(element_name)
        short_labels[element_name]
      end

      def reload!
        LOAD_MUTEX.synchronize do
          @elements = nil
          @sorted_elements = nil
          @short_labels = nil
          @loaded = false
          do_load_taxonomy
        end
      end

      private

      def load_taxonomy
        return if @loaded

        LOAD_MUTEX.synchronize do
          return if @loaded # Double-check after acquiring lock
          do_load_taxonomy
        end
      end

      def do_load_taxonomy
        @elements = {}
        parse_schema
        parse_labels
        parse_presentation
        @loaded = true
      end

      # Load and parse an XML file with error handling
      def load_xml_file(filename)
        file_path = TAXONOMY_DIR.join(filename)

        unless File.exist?(file_path)
          raise TaxonomyLoadError.new(
            "Taxonomy file not found: #{filename}",
            file_path: file_path.to_s
          )
        end

        doc = Nokogiri::XML(File.read(file_path))

        if doc.errors.any?
          Rails.logger.warn "XML parsing warnings in #{filename}: #{doc.errors.map(&:message).join(', ')}"
        end

        doc.remove_namespaces!
        doc
      rescue Errno::EACCES => e
        raise TaxonomyLoadError.new(
          "Permission denied reading taxonomy file: #{filename}",
          file_path: file_path.to_s,
          cause: e
        )
      rescue Nokogiri::XML::SyntaxError => e
        raise TaxonomyLoadError.new(
          "Invalid XML in taxonomy file: #{filename} - #{e.message}",
          file_path: file_path.to_s,
          cause: e
        )
      end

      # Parse XSD to extract element names and types
      def parse_schema
        doc = load_xml_file(SCHEMA_FILE)

        doc.xpath("//element[@abstract='false']").each do |el|
          name = el["name"]
          next if name.blank?

          type = determine_type(el)
          dimensional = DIMENSIONAL_ELEMENTS.include?(name)

          @elements[name] = TaxonomyElement.new(
            name: name,
            type: type,
            dimensional: dimensional
          )
        end
      end

      def determine_type(element_node)
        # Check explicit type attribute
        type_attr = element_node["type"]
        return TYPE_MAPPINGS[type_attr] if type_attr && TYPE_MAPPINGS.key?(type_attr)

        # Check for inline enumeration (Oui/Non = boolean)
        if element_node.at_xpath(".//enumeration[@value='Oui']")
          return :boolean
        end

        # Check for pureItemType with restrictions (percentage)
        if element_node.at_xpath(".//restriction[@base='xbrli:pureItemType']")
          return :decimal
        end

        # Default to string
        :string
      end

      # Parse label linkbase for French labels
      def parse_labels
        doc = load_xml_file(LABEL_FILE)

        # Build a map of label IDs to their text content
        labels = {}
        verbose_labels = {}

        doc.xpath("//label").each do |label_node|
          label_id = label_node["label"]
          role = label_node["role"] || ""
          text = label_node.text

          if role.include?("verboseLabel")
            verbose_labels[label_id] = text
          else
            labels[label_id] = text
          end
        end

        # Map labels to elements via labelArc
        doc.xpath("//labelArc").each do |arc|
          from = arc["from"]
          to = arc["to"]

          # Extract element name from locator reference (strix_a1101 -> a1101)
          element_name = from.sub(/^strix_/, "")

          element = @elements[element_name]
          next unless element

          # Update element attributes in place
          element.label = labels[to]
          element.verbose_label = verbose_labels[to] || labels[to]
        end
      end

      # Parse presentation linkbase for ordering and sections
      def parse_presentation
        doc = load_xml_file(PRESENTATION_FILE)

        # Track order within each section
        global_order = 0

        doc.xpath("//presentationLink").each do |link|
          role = link["role"] || ""
          section = extract_section_name(role)

          link.xpath(".//presentationArc").each do |arc|
            to = arc["to"]

            # Extract element name (strix_a1101 -> a1101)
            element_name = to.sub(/^strix_/, "")

            element = @elements[element_name]
            next unless element

            # Update element attributes in place
            global_order += 1
            element.section = section
            element.order = global_order
          end
        end
      end

      def extract_section_name(role_uri)
        # Extract readable section name from role URI
        # e.g., ".../role/Link_NoCountryDimension" -> "NoCountryDimension"
        match = role_uri.match(%r{/role/Link_(\w+)})
        match ? match[1].gsub("_", " ").strip : "General"
      end

      def load_short_labels
        return {} unless File.exist?(SHORT_LABELS_FILE)

        YAML.safe_load_file(SHORT_LABELS_FILE, permitted_classes: []) || {}
      rescue Psych::SyntaxError, Psych::DisallowedClass => e
        Rails.logger.warn "Failed to parse short labels YAML: #{e.message}"
        {}
      end
    end
  end
end
