import { Controller } from "@hotwired/stimulus"

// Manages dynamic field visibility in the transaction form based on type and payment method
export default class extends Controller {
  static targets = ["transactionType", "purchasePurpose", "paymentMethod", "cashAmount", "foreignCurrencyCashAmount", "rentalFields"]

  connect() {
    this.togglePurchasePurpose()
    this.toggleCashAmount()
    this.toggleRentalFields()
  }

  togglePurchasePurpose() {
    if (!this.hasTransactionTypeTarget || !this.hasPurchasePurposeTarget) return

    const transactionType = this.transactionTypeTarget.value
    const isPurchase = transactionType === "PURCHASE"

    this.purchasePurposeTarget.classList.toggle("hidden", !isPurchase)
  }

  toggleRentalFields() {
    if (!this.hasTransactionTypeTarget || !this.hasRentalFieldsTarget) return

    const isRental = this.transactionTypeTarget.value === "RENTAL"

    this.rentalFieldsTarget.classList.toggle("hidden", !isRental)
  }

  toggleCashAmount() {
    if (!this.hasPaymentMethodTarget || !this.hasCashAmountTarget) return

    const paymentMethod = this.paymentMethodTarget.value
    const hasCash = paymentMethod === "CASH" || paymentMethod === "MIXED"

    this.cashAmountTarget.classList.toggle("hidden", !hasCash)
    if (this.hasForeignCurrencyCashAmountTarget) {
      this.foreignCurrencyCashAmountTarget.classList.toggle("hidden", !hasCash)
    }
  }
}
