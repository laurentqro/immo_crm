# frozen_string_literal: true

# SubmissionRenderer generates output in multiple formats from a submission.
# Uses Taxonomy for element metadata and stored SubmissionValues for data.
#
# Supported formats:
# - XBRL XML (for AMSF submission)
# - HTML (for review interface)
# - Markdown (for export/documentation)
#
# Usage:
#   renderer = SubmissionRenderer.new(submission)
#   renderer.to_xbrl      # => XML string
#   renderer.to_html      # => HTML string
#   renderer.to_markdown  # => Markdown string
#
class SubmissionRenderer
  attr_reader :submission, :manifest

  def initialize(submission)
    @submission = submission
    @manifest = Xbrl::ElementManifest.new(submission)
  end

  # Render XBRL XML document
  def to_xbrl
    render_template("submissions/show", format: :xml)
  end

  # Render HTML review page
  def to_html
    render_template("submissions/rendered_review", format: :html)
  end

  # Render Markdown export
  def to_markdown
    org = submission.organization
    lines = []

    lines << "# AMSF Submission #{submission.year}"
    lines << ""
    lines << "**Organization:** #{org.name}"
    lines << "**RCI Number:** #{org.rci_number}"
    lines << "**Status:** #{submission.status_label}"
    lines << "**Generated:** #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    lines << ""
    lines << "---"
    lines << ""

    manifest.elements_by_section.each do |section, elements|
      lines << "## #{section}"
      lines << ""
      lines << "| Code | Description | Type | Value | Source |"
      lines << "|------|-------------|------|-------|--------|"

      elements.each do |ev|
        next if ev.blank?

        desc = ev.label_text&.truncate(60) || ev.name.humanize
        type = format_type_label(ev.type)
        value = format_markdown_value(ev.value, ev.element)
        source = ev.source || "—"

        lines << "| `#{ev.name}` | #{desc} | #{type} | #{value} | #{source} |"
      end

      lines << ""
    end

    lines << "---"
    lines << ""
    lines << "*Generated from AMSF taxonomy version #{submission.taxonomy_version}*"

    lines.join("\n")
  end

  # Suggested filename for XBRL export
  def suggested_filename
    "amsf_#{submission.year}_#{submission.organization.rci_number}.xml"
  end

  private

  def render_template(template_path, format:)
    lookup_context = ActionView::LookupContext.new(ActionController::Base.view_paths)
    renderer = ActionView::Base.with_empty_template_cache.new(
      lookup_context,
      assigns,
      nil
    )

    # Include helpers
    renderer.class.include(ActionView::Helpers)
    renderer.class.include(XbrlHelper) if defined?(XbrlHelper)
    renderer.class.include(Rails.application.routes.url_helpers)

    template = "#{template_path}.#{format}.erb"
    renderer.render(template: template)
  end

  def assigns
    {
      submission: submission,
      manifest: manifest,
      organization: submission.organization,
      taxonomy: Xbrl::Taxonomy
    }
  end

  def format_type_label(type)
    case type
    when :monetary then "EUR"
    when :integer then "Count"
    when :boolean then "Yes/No"
    when :decimal then "Decimal"
    when :string then "Text"
    else type.to_s.humanize
    end
  end

  def format_markdown_value(value, element)
    return "—" if value.blank?

    case element.type
    when :boolean
      value.to_s.downcase.in?(%w[true 1 yes oui]) ? "Yes" : "No"
    when :monetary
      "€#{format('%.2f', BigDecimal(value.to_s))}"
    when :integer
      value.to_i.to_s
    else
      value.to_s.truncate(40)
    end
  rescue ArgumentError
    value.to_s.truncate(40)
  end
end
