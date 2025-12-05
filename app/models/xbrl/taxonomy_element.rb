# frozen_string_literal: true

module Xbrl
  # TaxonomyElement represents a single XBRL element from the AMSF taxonomy.
  # Metadata is parsed from taxonomy files; computation logic lives in ElementManifest.
  #
  # Sources:
  # - name, type: from .xsd schema
  # - label, verbose_label: from _lab.xml linkbase
  # - order, section: from _pre.xml presentation linkbase
  #
  class TaxonomyElement
    attr_reader :name, :type, :label, :verbose_label, :section, :order, :dimensional

    def initialize(name:, type:, label: nil, verbose_label: nil, section: nil, order: 0, dimensional: false)
      @name = name
      @type = type
      @label = label
      @verbose_label = verbose_label
      @section = section
      @order = order
      @dimensional = dimensional
    end

    def monetary?
      type == :monetary
    end

    def integer?
      type == :integer
    end

    def boolean?
      type == :boolean
    end

    def string?
      type == :string
    end

    def numeric?
      monetary? || integer?
    end

    def dimensional?
      @dimensional
    end

    # Strip HTML tags for plain text display
    def label_text
      return nil if label.blank?

      ActionController::Base.helpers.strip_tags(label).squish
    end

    # Strip HTML tags from verbose label
    def verbose_label_text
      return nil if verbose_label.blank?

      ActionController::Base.helpers.strip_tags(verbose_label).squish
    end

    # Manual short label from config/xbrl_short_labels.yml
    # Falls back to humanized element name if not defined
    def short_label
      Xbrl::Taxonomy.short_label_for(name) || name.humanize
    end

    # Label for tooltip display - prefers verbose label, falls back to regular label
    def tooltip_label
      verbose_label_text.presence || label_text
    end

    # XBRL unit reference based on type
    def unit_ref
      case type
      when :monetary then "unit_EUR"
      when :integer then "unit_pure"
      else nil
      end
    end

    # XBRL decimals attribute for monetary values
    def decimals
      monetary? ? "2" : nil
    end

    def to_h
      {
        name: name,
        type: type,
        label: label,
        verbose_label: verbose_label,
        section: section,
        order: order,
        dimensional: dimensional
      }
    end
  end
end
