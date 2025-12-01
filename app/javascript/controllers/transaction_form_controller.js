import { Controller } from "@hotwired/stimulus"

// Manages dynamic field visibility in the transaction form based on type and payment method
export default class extends Controller {
  static targets = ["transactionType", "purchasePurpose", "paymentMethod", "cashAmount"]

  connect() {
    this.togglePurchasePurpose()
    this.toggleCashAmount()
  }

  togglePurchasePurpose() {
    if (!this.hasTransactionTypeTarget || !this.hasPurchasePurposeTarget) return

    const transactionType = this.transactionTypeTarget.value
    const isPurchase = transactionType === "PURCHASE"

    this.purchasePurposeTarget.classList.toggle("hidden", !isPurchase)
  }

  toggleCashAmount() {
    if (!this.hasPaymentMethodTarget || !this.hasCashAmountTarget) return

    const paymentMethod = this.paymentMethodTarget.value
    const hasCash = paymentMethod === "CASH" || paymentMethod === "MIXED"

    this.cashAmountTarget.classList.toggle("hidden", !hasCash)
  }
}
