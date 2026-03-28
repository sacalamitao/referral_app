import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "amountInput"]

  connect() {
    this.applyClosedState()
    this.dialogTarget.style.display = "none"
    document.body.classList.remove("overflow-hidden")
  }

  open(event) {
    event?.preventDefault()
    if (!this.hasDialogTarget) return

    this.dialogTarget.classList.remove("invisible", "opacity-0", "pointer-events-none")
    this.dialogTarget.style.display = "flex"
    document.body.classList.add("overflow-hidden")
    this.amountInputTarget?.focus()
  }

  close(event) {
    event?.preventDefault()
    if (!this.hasDialogTarget) return

    this.applyClosedState()
    document.body.classList.remove("overflow-hidden")
  }

  closeOnBackdrop(event) {
    if (event.target !== this.dialogTarget) return
    this.close()
  }

  closeOnEscape(event) {
    if (event.key !== "Escape") return
    if (this.dialogTarget.classList.contains("invisible")) return

    this.close()
  }

  setMaxPayout(event) {
    event.preventDefault()
    if (!this.hasAmountInputTarget) return

    const maxAmount = event.currentTarget.dataset.maxAmount
    if (!maxAmount) return

    this.amountInputTarget.value = maxAmount
    this.amountInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  applyClosedState() {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.add("invisible", "opacity-0", "pointer-events-none")
    this.dialogTarget.style.display = "none"
  }
}
