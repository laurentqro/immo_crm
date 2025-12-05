# frozen_string_literal: true

# Helper methods for rendering XBRL-related views.
# Used by both XBRL XML templates and HTML review pages.
#
module XbrlHelper
  # Parse country data from JSON string or return hash as-is.
  # Returns nil if value is not a valid country breakdown hash.
  def parse_country_data(value)
    return value if value.is_a?(Hash)
    return nil if value.blank?

    parsed = JSON.parse(value)
    parsed.is_a?(Hash) ? parsed : nil
  rescue JSON::ParserError, TypeError
    nil
  end

  # Format value for XBRL output
  def format_xbrl_value(value, element)
    return "" if value.blank?
    return CGI.escapeHTML(value.to_s) if element.nil?

    case element.type
    when :boolean
      value.to_s.downcase.in?(%w[true 1 yes oui]) ? "Oui" : "Non"
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
      value.to_s.downcase.in?(%w[true 1 yes oui]) ? "Yes" : "No"
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
end
