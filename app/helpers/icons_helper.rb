# frozen_string_literal: true

# Centralized SVG icon helper for consistent icon rendering across the app.
# Uses tag helpers to avoid html_safe XSS concerns.
#
# Usage:
#   <%= arrow_up_icon %>
#   <%= arrow_down_icon(class: "h-6 w-6") %>
#
module IconsHelper
  # Arrow pointing up (Heroicons style)
  def arrow_up_icon(options = {})
    icon_class = options.delete(:class) || "h-4 w-4 inline"

    tag.svg(
      xmlns: "http://www.w3.org/2000/svg",
      class: icon_class,
      fill: "none",
      viewBox: "0 0 24 24",
      stroke: "currentColor",
      **options
    ) do
      tag.path(
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "stroke-width": "2",
        d: "M5 10l7-7m0 0l7 7m-7-7v18"
      )
    end
  end

  # Arrow pointing down (Heroicons style)
  def arrow_down_icon(options = {})
    icon_class = options.delete(:class) || "h-4 w-4 inline"

    tag.svg(
      xmlns: "http://www.w3.org/2000/svg",
      class: icon_class,
      fill: "none",
      viewBox: "0 0 24 24",
      stroke: "currentColor",
      **options
    ) do
      tag.path(
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "stroke-width": "2",
        d: "M19 14l-7 7m0 0l-7-7m7 7V3"
      )
    end
  end
end
