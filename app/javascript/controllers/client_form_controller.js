import { Controller } from "@hotwired/stimulus"

// Manages dynamic field visibility in the client form based on client type, PEP status,
// and due diligence level
export default class extends Controller {
  static targets = [
    "clientType",
    "legalPersonType",
    "businessSector",
    "isPep",
    "pepType",
    "dueDiligenceLevel",
    "simplifiedDdReason"
  ]

  connect() {
    this.toggleFields()
    this.togglePepType()
    this.toggleSimplifiedReason()
  }

  toggleFields() {
    const clientType = this.clientTypeTarget.value
    const isLegalEntity = clientType === "PM"

    // Show/hide legal entity specific fields
    if (this.hasLegalPersonTypeTarget) {
      this.legalPersonTypeTarget.classList.toggle("hidden", !isLegalEntity)
    }
    if (this.hasBusinessSectorTarget) {
      this.businessSectorTarget.classList.toggle("hidden", !isLegalEntity)
    }
  }

  togglePepType() {
    const isPep = this.isPepTarget.checked

    if (this.hasPepTypeTarget) {
      this.pepTypeTarget.classList.toggle("hidden", !isPep)
    }
  }

  toggleSimplifiedReason() {
    if (!this.hasDueDiligenceLevelTarget || !this.hasSimplifiedDdReasonTarget) return

    const isSimplified = this.dueDiligenceLevelTarget.value === "SIMPLIFIED"
    this.simplifiedDdReasonTarget.classList.toggle("hidden", !isSimplified)
  }
}
