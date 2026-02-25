import { Controller } from "@hotwired/stimulus"

// Manages dynamic field visibility in the beneficial owner form
export default class extends Controller {
  static targets = ["isPep", "pepType"]

  connect() {
    this.togglePepType()
  }

  togglePepType() {
    if (!this.hasIsPepTarget || !this.hasPepTypeTarget) return

    const isPep = this.isPepTarget.checked

    this.pepTypeTarget.classList.toggle("hidden", !isPep)
  }
}
