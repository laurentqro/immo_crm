import { Controller } from "@hotwired/stimulus"

// Handles onboarding wizard form enhancements.
// Progressive enhancement - forms work without JavaScript.
//
// Usage in views:
//   <form data-controller="onboarding" data-onboarding-submitting-class="opacity-50">
//     <button data-onboarding-target="submit">Continue</button>
//   </form>
export default class extends Controller {
  static targets = ["submit", "form"]
  static classes = ["submitting"]

  connect() {
    this.form = this.element.tagName === "FORM" ? this.element : this.element.querySelector("form")
    if (this.form) {
      this.form.addEventListener("turbo:submit-start", this.disableSubmit.bind(this))
      this.form.addEventListener("turbo:submit-end", this.enableSubmit.bind(this))
    }
  }

  disconnect() {
    if (this.form) {
      this.form.removeEventListener("turbo:submit-start", this.disableSubmit.bind(this))
      this.form.removeEventListener("turbo:submit-end", this.enableSubmit.bind(this))
    }
  }

  // Disable submit button during form submission to prevent double-clicks
  disableSubmit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("cursor-not-allowed")
    }
    if (this.hasSubmittingClass) {
      this.element.classList.add(this.submittingClass)
    }
  }

  // Re-enable submit button after submission completes (success or failure)
  enableSubmit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("cursor-not-allowed")
    }
    if (this.hasSubmittingClass) {
      this.element.classList.remove(this.submittingClass)
    }
  }

  // Validate required fields before form submission
  // Called via data-action="submit->onboarding#validate"
  validate(event) {
    const requiredFields = this.form.querySelectorAll("[required]")
    let valid = true

    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        valid = false
        field.classList.add("border-red-500")
      } else {
        field.classList.remove("border-red-500")
      }
    })

    if (!valid) {
      event.preventDefault()
    }
  }
}
