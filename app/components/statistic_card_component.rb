# frozen_string_literal: true

# StatisticCardComponent displays a single statistic value with optional
# year-over-year comparison indicator.
#
# Usage:
#   <%= render StatisticCardComponent.new(
#     label: "Total Clients",
#     value: 120,
#     previous_value: 100,
#     element_name: "a1101"
#   ) %>
#
class StatisticCardComponent < JumpstartComponent
  include AmsfConstants
  include IconsHelper

  attr_reader :label, :value, :previous_value, :element_name,
    :editable, :unit, :tooltip

  def initialize(opts = {})
    opts.deep_symbolize_keys!
    @label = opts[:label]
    @value = opts[:value]
    @previous_value = opts[:previous_value]
    @element_name = opts[:element_name]
    @editable = opts.fetch(:editable, false)
    @unit = opts[:unit]
    @tooltip = opts[:tooltip]
  end

  def editable?
    !!@editable
  end

  def has_comparison?
    previous_value.present? && numeric_value.present? && numeric_previous.present?
  end

  def change_percent
    return nil unless has_comparison?
    return nil if numeric_previous.zero?

    ((numeric_value - numeric_previous) / numeric_previous * 100).round(1)
  end

  def significant?
    return false unless change_percent

    change_percent.abs > SIGNIFICANCE_THRESHOLD
  end

  def trend_direction
    return nil unless change_percent

    if change_percent.positive?
      :up
    elsif change_percent.negative?
      :down
    else
      :unchanged
    end
  end

  def trend_class
    return "" unless significant?

    case trend_direction
    when :up then "text-amber-600"
    when :down then "text-amber-600"
    else ""
    end
  end

  def trend_icon
    case trend_direction
    when :up then arrow_up_icon
    when :down then arrow_down_icon
    else ""
    end
  end

  def formatted_value
    case unit
    when :currency
      format_currency(numeric_value)
    when :percent
      "#{value}%"
    else
      value.to_s
    end
  end

  def formatted_change
    return nil unless change_percent

    sign = change_percent.positive? ? "+" : ""
    "#{sign}#{change_percent}%"
  end

  private

  def numeric_value
    BigDecimal(value.to_s)
  rescue ArgumentError, TypeError, FloatDomainError => e
    Rails.logger.warn("StatisticCardComponent: Failed to parse value '#{value}' for #{element_name}: #{e.message}")
    nil
  end

  def numeric_previous
    BigDecimal(previous_value.to_s)
  rescue ArgumentError, TypeError, FloatDomainError => e
    Rails.logger.warn("StatisticCardComponent: Failed to parse previous_value '#{previous_value}' for #{element_name}: #{e.message}")
    nil
  end

  def format_currency(amount)
    return "0" unless amount

    number = amount.to_f
    if number >= 1_000_000
      "#{(number / 1_000_000).round(1)}M"
    elsif number >= 1_000
      "#{(number / 1_000).round(1)}K"
    else
      number.round(0).to_s
    end
  end

  # Icon methods provided by IconsHelper
end
