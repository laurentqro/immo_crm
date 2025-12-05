# frozen_string_literal: true

# Helper methods for rendering XBRL-related views.
# Used by both XBRL XML templates and HTML review pages.
#
module XbrlHelper
  # Check if a string is a valid ISO 3166-1 alpha-2 country code
  # Uses the countries gem for authoritative validation
  def valid_country_code?(code)
    code.is_a?(String) && ISO3166::Country.new(code).present?
  end

  # Parse country data from JSON string or return hash as-is.
  # Returns nil if value is not a valid country breakdown hash.
  # Filters out invalid country codes with a warning.
  def parse_country_data(value)
    raw_data = parse_country_json(value)
    return nil unless raw_data.is_a?(Hash)

    # Filter to valid ISO country codes only
    validated = raw_data.select do |code, _count|
      if valid_country_code?(code)
        true
      else
        Rails.logger.warn "Invalid country code in XBRL data: #{code.inspect}"
        false
      end
    end

    validated.presence
  end

  # Format value for XBRL instance document output
  def format_xbrl_value(value, element)
    return "" if value.blank?
    return CGI.escapeHTML(value.to_s) if element.nil?

    case element.type
    when :boolean
      parse_boolean(value) ? "Oui" : "Non"
    when :monetary
      format("%.2f", BigDecimal(value.to_s))
    when :integer
      value.to_i.to_s
    else
      CGI.escapeHTML(value.to_s)
    end
  rescue ArgumentError
    CGI.escapeHTML(value.to_s)
  end

  # Format value for HTML display
  def format_html_value(value, element)
    return content_tag(:span, "—", class: "text-gray-400") if value.blank?
    return h(value.to_s) if element.nil?

    case element.type
    when :boolean
      parse_boolean(value) ? "Yes" : "No"
    when :monetary
      number_to_currency(value, unit: "€", format: "%n %u")
    when :integer
      number_with_delimiter(value.to_i)
    when :decimal
      number_with_precision(value.to_f, precision: 2)
    else
      h(value.to_s)
    end
  rescue ArgumentError
    h(value.to_s)
  end

  # Badge CSS classes for element source
  def source_badge_class(source)
    case source
    when "calculated" then "bg-blue-100 text-blue-800"
    when "from_settings" then "bg-purple-100 text-purple-800"
    when "manual" then "bg-green-100 text-green-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  # Human-readable source label
  def source_label(source)
    case source
    when "calculated" then "Calculated"
    when "from_settings" then "From Settings"
    when "manual" then "Manual"
    else source&.humanize || "Unknown"
    end
  end

  # Type badge CSS classes
  def type_badge_class(type)
    case type
    when :monetary then "bg-green-50 text-green-700"
    when :integer then "bg-blue-50 text-blue-700"
    when :boolean then "bg-yellow-50 text-yellow-700"
    when :decimal then "bg-indigo-50 text-indigo-700"
    else "bg-gray-50 text-gray-700"
    end
  end

  # Type label for display
  def type_label(type)
    case type
    when :monetary then "EUR"
    when :integer then "Count"
    when :boolean then "Yes/No"
    when :decimal then "Decimal"
    when :string then "Text"
    else type.to_s.humanize
    end
  end

  # Render element label with tooltip icon showing full description.
  # Uses short_label as display text and a question mark icon for the tooltip.
  #
  # @param element [Xbrl::TaxonomyElement, Xbrl::ElementManifest::ElementValue] Element with label methods
  # @param show_code [Boolean] Whether to show element code below label
  # @return [String] HTML for label with tooltip icon
  def element_label_with_tooltip(element, show_code: true)
    return "" if element.nil?

    label_html = content_tag(:span, class: "inline-flex items-center gap-1") do
      short_label = content_tag(:span, element.short_label)
      tooltip_icon = tooltip_question_mark(element.tooltip_label)
      safe_join([short_label, tooltip_icon])
    end

    if show_code
      code_html = content_tag(:div, element.name,
        class: "text-xs text-gray-400 dark:text-gray-500 font-mono mt-1")
      safe_join([label_html, code_html])
    else
      label_html
    end
  end

  # Simple tooltip span for inline use
  #
  # @param element [Xbrl::TaxonomyElement, Xbrl::ElementManifest::ElementValue] Element with label methods
  # @return [String] HTML span with short label and tooltip icon
  def element_tooltip_label(element)
    return "" if element.nil?

    content_tag(:span, class: "inline-flex items-center gap-1") do
      short_label = content_tag(:span, element.short_label)
      tooltip_icon = tooltip_question_mark(element.tooltip_label)
      safe_join([short_label, tooltip_icon])
    end
  end

  # Render short label with tooltip icon for a stat card, given element name
  # Use this in stat cards where you have the element code as a string
  #
  # @param element_name [String] XBRL element name (e.g., "a1101")
  # @param fallback [String] Fallback label if element not found
  # @return [String] HTML span with short label and tooltip icon
  def stat_label(element_name, fallback: nil)
    element = Xbrl::Taxonomy.element(element_name)

    if element
      content_tag(:span, class: "inline-flex items-center gap-1") do
        short_label = content_tag(:span, element.short_label)
        tooltip_icon = tooltip_question_mark(element.tooltip_label)
        safe_join([short_label, tooltip_icon])
      end
    else
      fallback || element_name.humanize
    end
  end

  # Render a question mark icon with tooltip
  #
  # @param tooltip_text [String] Text to show in tooltip
  # @return [String] HTML for question mark icon with tooltip
  def tooltip_question_mark(tooltip_text)
    return "" if tooltip_text.blank?

    content_tag(:span,
      class: "inline-flex items-center justify-center w-4 h-4 rounded-full bg-gray-200 dark:bg-gray-600 text-gray-500 dark:text-gray-300 text-xs cursor-help",
      data: {
        controller: "tooltip",
        tooltip_content_value: tooltip_text,
        tooltip_allow_html_value: false
      }) do
      "?"
    end
  end

  private

  def parse_country_json(value)
    return value if value.is_a?(Hash)
    return nil if value.blank?

    parsed = JSON.parse(value)
    parsed.is_a?(Hash) ? parsed : nil
  rescue JSON::ParserError, TypeError
    nil
  end

  def parse_boolean(value)
    value.to_s.downcase.in?(%w[true 1 yes oui])
  end
end
