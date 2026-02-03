import { Controller } from "@hotwired/stimulus"

// Manages dynamic field visibility in the client form based on client type, PEP status,
// and due diligence level
export default class extends Controller {
  static targets = [
    "clientType",
    "legalPersonType",
    "businessSector",
    "trusteeSection",
    "incorporationCountry",
    "naturalPersonFields",
    "isPep",
    "pepType",
    "dueDiligenceLevel",
    "simplifiedDdReason",
    "introducedByThirdParty",
    "introducerCountry",
    "thirdPartyCdd",
    "thirdPartyCddType",
    "thirdPartyCddCountry"
  ]

  connect() {
    this.toggleFields()
    this.togglePepType()
    this.toggleSimplifiedReason()
    this.toggleIntroducerCountry()
    this.toggleThirdPartyCdd()
  }

  toggleFields() {
    // Get client type from radio button (checked) or select (value)
    const clientType = this.element.querySelector('input[name="client[client_type]"]:checked')?.value
      || this.clientTypeTarget?.value
    const isLegalEntity = clientType === "LEGAL_ENTITY"
    const isTrust = clientType === "TRUST"
    const isNaturalPerson = clientType === "NATURAL_PERSON"

    // Show/hide legal entity specific fields
    if (this.hasLegalPersonTypeTarget) {
      this.legalPersonTypeTarget.classList.toggle("hidden", !isLegalEntity)
    }
    if (this.hasBusinessSectorTarget) {
      this.businessSectorTarget.classList.toggle("hidden", !isLegalEntity)
    }
    // Show/hide trust specific fields
    if (this.hasTrusteeSectionTarget) {
      this.trusteeSectionTarget.classList.toggle("hidden", !isTrust)
    }
    // Show/hide incorporation country for legal entities and trusts
    if (this.hasIncorporationCountryTarget) {
      this.incorporationCountryTarget.classList.toggle("hidden", !isLegalEntity && !isTrust)
    }
    // Show/hide nationality and residence fields (only for natural persons and trusts, not legal entities)
    if (this.hasNaturalPersonFieldsTarget) {
      this.naturalPersonFieldsTarget.classList.toggle("hidden", isLegalEntity)
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

  toggleIntroducerCountry() {
    if (!this.hasIntroducedByThirdPartyTarget || !this.hasIntroducerCountryTarget) return

    const isIntroduced = this.introducedByThirdPartyTarget.checked
    this.introducerCountryTarget.classList.toggle("hidden", !isIntroduced)
  }

  toggleThirdPartyCdd() {
    if (!this.hasThirdPartyCddTarget) return

    const isEnabled = this.thirdPartyCddTarget.checked

    // Show/hide type radio buttons
    if (this.hasThirdPartyCddTypeTarget) {
      this.thirdPartyCddTypeTarget.classList.toggle("hidden", !isEnabled)
    }

    // Show/hide country field (only if enabled AND type is FOREIGN)
    if (this.hasThirdPartyCddCountryTarget) {
      const typeValue = this.element.querySelector('input[name="client[third_party_cdd_type]"]:checked')?.value
      const showCountry = isEnabled && typeValue === "FOREIGN"
      this.thirdPartyCddCountryTarget.classList.toggle("hidden", !showCountry)
    }
  }
}
