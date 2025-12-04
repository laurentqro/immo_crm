# frozen_string_literal: true

# StatisticGroupComponent groups multiple StatisticCardComponents under a title.
#
# Usage:
#   <%= render StatisticGroupComponent.new(
#     title: "Client Statistics",
#     description: "Overview of client data for the submission year"
#   ) do |group| %>
#     <% group.with_card(label: "Total Clients", value: 120, element_name: "a1101") %>
#     <% group.with_card(label: "Natural Persons", value: 80, element_name: "a1102") %>
#   <% end %>
#
class StatisticGroupComponent < JumpstartComponent
  # Use ViewComponent's built-in slot management to avoid memory leaks
  renders_many :cards, StatisticCardComponent

  attr_reader :title, :description, :collapsible, :collapsed, :columns

  def initialize(opts = {})
    opts.deep_symbolize_keys!
    @title = opts[:title]
    @description = opts[:description]
    @collapsible = opts.fetch(:collapsible, false)
    @collapsed = opts.fetch(:collapsed, false)
    @columns = opts.fetch(:columns, 3)
  end

  def collapsible?
    !!@collapsible
  end

  def collapsed?
    collapsible? && !!@collapsed
  end

  def grid_class
    case columns
    when 1 then "grid-cols-1"
    when 2 then "grid-cols-1 sm:grid-cols-2"
    when 3 then "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
    when 4 then "grid-cols-1 sm:grid-cols-2 lg:grid-cols-4"
    else "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
    end
  end

  def has_significant_changes?
    cards.any?(&:significant?)
  end
end
