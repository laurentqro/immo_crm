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
  # Raised when rendering fails due to template or data errors
  class RenderError < StandardError
    attr_reader :format, :cause, :submission_id

    def initialize(message, format: nil, cause: nil, submission_id: nil)
      @format = format
      @cause = cause
      @submission_id = submission_id
      super(message)
    end
  end

  attr_reader :submission, :manifest

  def initialize(submission)
    @submission = submission
    @manifest = Xbrl::ElementManifest.new(submission)
  end

  # Render XBRL XML document
  # Uses gem for supported years, falls back to ERB template otherwise
  def to_xbrl
    if gem_supported_year?
      generate_xbrl_via_gem
    else
      render_template("submissions/show", format: :xml)
    end
  rescue ActionView::Template::Error => e
    raise RenderError.new(
      "Failed to render XBRL for submission #{submission&.id}: #{e.message}",
      format: :xbrl,
      cause: e,
      submission_id: submission&.id
    )
  rescue AmsfSurvey::GeneratorError => e
    raise RenderError.new(
      "Failed to generate XBRL via gem for submission #{submission&.id}: #{e.message}",
      format: :xbrl,
      cause: e,
      submission_id: submission&.id
    )
  end

  # Render HTML review page
  def to_html
    render_template("submissions/rendered_review", format: :html)
  rescue ActionView::Template::Error => e
    raise RenderError.new(
      "Failed to render HTML for submission #{submission&.id}: #{e.message}",
      format: :html,
      cause: e,
      submission_id: submission&.id
    )
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
        type = ev.element.type_label
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
  rescue StandardError => e
    raise RenderError.new(
      "Failed to render Markdown for submission #{submission&.id}: #{e.message}",
      format: :markdown,
      cause: e,
      submission_id: submission&.id
    )
  end

  # Suggested filename for XBRL export
  def suggested_filename
    "amsf_#{submission.year}_#{submission.organization.rci_number}.xml"
  end

  private

  # Check if the submission year is supported by the gem
  def gem_supported_year?
    AmsfSurvey.registered?(:real_estate) &&
      AmsfSurvey.supported_years(:real_estate).include?(submission.year)
  end

  # Generate XBRL using the gem
  def generate_xbrl_via_gem
    gem_submission = create_gem_submission
    AmsfSurvey.to_xbrl(gem_submission, pretty: true)
  end

  # Create a gem submission from the AR submission
  def create_gem_submission
    gem_sub = AmsfSurvey.build_submission(
      industry: :real_estate,
      year: submission.year,
      entity_id: submission.organization.rci_number,
      period: Date.new(submission.year, 12, 31)
    )

    # Transfer values from AR submission to gem submission
    submission.submission_values.each do |sv|
      next unless sv.value.present?

      begin
        gem_sub[sv.element_name.to_sym] = sv.value
      rescue AmsfSurvey::UnknownFieldError
        Rails.logger.debug "Skipping unknown gem field: #{sv.element_name}"
      end
    end

    gem_sub
  end

  def render_template(template_path, format:)
    ApplicationController.render(
      template: template_path,
      formats: [format],
      assigns: assigns
    )
  end

  def assigns
    {
      submission: submission,
      manifest: manifest,
      organization: submission.organization,
      taxonomy: Xbrl::Taxonomy
    }
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
