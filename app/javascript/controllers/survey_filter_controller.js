import { Controller } from "@hotwired/stimulus"

// Client-side filtering controller for AMSF survey review page.
// Provides instant text search and "needs review" filtering without server round-trips.
//
// Usage:
//   <div data-controller="survey-filter">
//     <input data-survey-filter-target="search" data-action="input->survey-filter#filterDebounced">
//     <input type="checkbox" data-survey-filter-target="needsReviewOnly" data-action="change->survey-filter#filter">
//     <span data-survey-filter-target="count">X</span> elements
//
//     <div data-survey-filter-target="sections">
//       <div data-survey-filter-target="section">
//         <tr data-survey-filter-target="element"
//             data-element-name="a1101"
//             data-element-label="some label"
//             data-needs-review="true">
//       </div>
//     </div>
//   </div>
export default class extends Controller {
  static targets = ["search", "needsReviewOnly", "count", "sections", "section", "element", "sectionCount"]

  // Debounce delay in milliseconds
  static DEBOUNCE_MS = 150

  connect() {
    // Store original counts for reset
    this.totalCount = this.elementTargets.length
    this.debounceTimer = null
  }

  disconnect() {
    // Clean up timer on disconnect
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  // Debounced filter for text input - waits 150ms after last keystroke
  filterDebounced() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    this.debounceTimer = setTimeout(() => {
      this.filter()
    }, this.constructor.DEBOUNCE_MS)
  }

  // Main filter method - combines text search and needs review filter
  // Called directly for checkbox changes, debounced for text input
  filter() {
    const searchTerm = this.hasSearchTarget ? this.searchTarget.value.toLowerCase().trim() : ""
    const needsReviewOnly = this.hasNeedsReviewOnlyTarget ? this.needsReviewOnlyTarget.checked : false

    let visibleCount = 0

    // Filter each element
    this.elementTargets.forEach(element => {
      const matchesSearch = this.matchesSearch(element, searchTerm)
      const matchesReview = this.matchesReviewFilter(element, needsReviewOnly)

      const isVisible = matchesSearch && matchesReview
      element.style.display = isVisible ? "" : "none"

      if (isVisible) {
        visibleCount++
      }
    })

    // Update count display
    this.updateCount(visibleCount)

    // Hide sections with no visible elements
    this.updateSectionVisibility()
  }

  // Check if element matches text search
  matchesSearch(element, searchTerm) {
    if (!searchTerm) return true

    const name = (element.dataset.elementName || "").toLowerCase()
    const label = (element.dataset.elementLabel || "").toLowerCase()

    return name.includes(searchTerm) || label.includes(searchTerm)
  }

  // Check if element matches needs review filter
  matchesReviewFilter(element, needsReviewOnly) {
    if (!needsReviewOnly) return true

    return element.dataset.needsReview === "true"
  }

  // Update the element count display
  updateCount(count) {
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
    }
  }

  // Hide/show sections based on visible elements
  updateSectionVisibility() {
    this.sectionTargets.forEach(section => {
      const elements = section.querySelectorAll('[data-survey-filter-target="element"]')
      const visibleElements = Array.from(elements).filter(el => el.style.display !== "none")

      section.style.display = visibleElements.length > 0 ? "" : "none"

      // Update section element count if available
      const sectionCountEl = section.querySelector('[data-survey-filter-target="sectionCount"]')
      if (sectionCountEl) {
        sectionCountEl.textContent = visibleElements.length
      }
    })
  }

  // Reset all filters
  reset() {
    if (this.hasSearchTarget) {
      this.searchTarget.value = ""
    }
    if (this.hasNeedsReviewOnlyTarget) {
      this.needsReviewOnlyTarget.checked = false
    }
    this.filter()
  }
}
