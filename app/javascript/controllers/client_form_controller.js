import { Controller } from "@hotwired/stimulus"

// Manages dynamic field visibility in the client form based on client type, PEP status,
// and due diligence level
export default class extends Controller {
  static targets = [
    "clientType",
    "legalEntityType",
    "businessSector",
    "trusteeSection",
    "trusteesContainer",
    "trusteeEntry",
    "countryOptions",
    "incorporationCountry",
    "naturalPersonFields",
    "isPep",
    "pepType",
    "isVasp",
    "vaspType",
    "legalEntityTypeOther",
    "vaspOtherServiceType",
    "dueDiligenceLevel",
    "simplifiedDdReason",
    "introducedByThirdParty",
    "introducerCountry",
    "thirdPartyCdd",
    "thirdPartyCddType",
    "thirdPartyCddCountry"
  ]

  connect() {
    this.trusteeCounter = 0
    this.toggleFields()
    this.toggleLegalEntityType()
    this.togglePepType()
    this.toggleVaspType()
    this.toggleSimplifiedReason()
    this.toggleIntroducerCountry()
    this.toggleThirdPartyCdd()
  }

  toggleFields() {
    // Get client type from radio button (checked) or select (value)
    const clientType = this.element.querySelector('input[name="client[client_type]"]:checked')?.value
      || this.clientTypeTarget?.value
    const isLegalEntity = clientType === "LEGAL_ENTITY"
    const isNaturalPerson = clientType === "NATURAL_PERSON"

    // Show/hide legal entity specific fields
    if (this.hasLegalEntityTypeTarget) {
      this.legalEntityTypeTarget.classList.toggle("hidden", !isLegalEntity)
    }
    if (this.hasBusinessSectorTarget) {
      this.businessSectorTarget.classList.toggle("hidden", !isLegalEntity)
    }
    // Show/hide incorporation country for legal entities
    if (this.hasIncorporationCountryTarget) {
      this.incorporationCountryTarget.classList.toggle("hidden", !isLegalEntity)
    }
    // Show/hide nationality and residence fields (only for natural persons, not legal entities)
    if (this.hasNaturalPersonFieldsTarget) {
      this.naturalPersonFieldsTarget.classList.toggle("hidden", isLegalEntity)
    }

    // Re-evaluate legal entity type dependent fields
    this.toggleLegalEntityType()
  }

  toggleLegalEntityType() {
    if (!this.hasLegalEntityTypeTarget) return

    const legalEntityTypeSelect = this.legalEntityTypeTarget.querySelector("select")
    const value = legalEntityTypeSelect?.value
    const isLegalEntity = !this.legalEntityTypeTarget.classList.contains("hidden")

    // Show/hide "other" text field
    if (this.hasLegalEntityTypeOtherTarget) {
      const isOther = value === "OTHER"
      this.legalEntityTypeOtherTarget.classList.toggle("hidden", !(isLegalEntity && isOther))
    }

    // Show/hide trustee section when legal entity type is TRUST
    if (this.hasTrusteeSectionTarget) {
      const isTrust = isLegalEntity && value === "TRUST"
      this.trusteeSectionTarget.classList.toggle("hidden", !isTrust)
    }
  }

  togglePepType() {
    const isPep = this.isPepTarget.checked

    if (this.hasPepTypeTarget) {
      this.pepTypeTarget.classList.toggle("hidden", !isPep)
    }
  }

  toggleVaspType() {
    if (!this.hasIsVaspTarget || !this.hasVaspTypeTarget) return

    const isVasp = this.isVaspTarget.checked
    this.vaspTypeTarget.classList.toggle("hidden", !isVasp)

    // Show/hide free-text field for "OTHER" vasp type
    if (this.hasVaspOtherServiceTypeTarget) {
      const vaspTypeSelect = this.vaspTypeTarget.querySelector("select")
      const isOther = isVasp && vaspTypeSelect?.value === "OTHER"
      this.vaspOtherServiceTypeTarget.classList.toggle("hidden", !isOther)
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

  addTrustee() {
    if (!this.hasTrusteesContainerTarget) return

    const container = this.trusteesContainerTarget
    const id = `new_${++this.trusteeCounter}`

    // Clone country options from the reference select, clearing any pre-selection
    let countryOptionsHtml = '<option value="">Select country...</option>'
    if (this.hasCountryOptionsTarget) {
      const temp = this.countryOptionsTarget.cloneNode(true)
      temp.selectedIndex = 0
      Array.from(temp.options).forEach(opt => opt.removeAttribute("selected"))
      countryOptionsHtml = temp.innerHTML
    }

    const template = `
      <div class="trustee-entry border-b pb-3 mb-3" style="border-color: var(--base-border-tertiary);" data-client-form-target="trusteeEntry">
        <div class="grid sm:grid-cols-3 gap-4">
          <div class="form-group">
            <label for="client_trustees_attributes_${id}_name">Trustee name</label>
            <input type="text" name="client[trustees_attributes][${id}][name]" id="client_trustees_attributes_${id}_name" class="form-control">
          </div>
          <div class="form-group">
            <label for="client_trustees_attributes_${id}_nationality">Nationality</label>
            <select name="client[trustees_attributes][${id}][nationality]" id="client_trustees_attributes_${id}_nationality" class="form-control">
              ${countryOptionsHtml}
            </select>
          </div>
          <div class="form-group flex items-end gap-4">
            <div class="form-picker-group flex-1">
              <input type="hidden" name="client[trustees_attributes][${id}][is_professional]" value="0">
              <input type="checkbox" name="client[trustees_attributes][${id}][is_professional]" id="client_trustees_attributes_${id}_is_professional" value="1">
              <div>
                <label for="client_trustees_attributes_${id}_is_professional">Professional</label>
              </div>
            </div>
            <button type="button" class="btn btn-sm text-red-600" data-action="client-form#removeTrustee">Remove</button>
          </div>
        </div>
      </div>
    `
    container.insertAdjacentHTML("beforeend", template)
  }

  removeTrustee(event) {
    const entry = event.target.closest("[data-client-form-target='trusteeEntry']")
    if (!entry) return

    const destroyField = entry.querySelector("input[name*='_destroy']")
    if (destroyField) {
      // For persisted records, mark for destruction and hide
      destroyField.value = "1"
      entry.style.display = "none"
    } else {
      // For new records, just remove the DOM element
      entry.remove()
    }
  }
}
