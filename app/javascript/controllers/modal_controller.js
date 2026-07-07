import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const modalId = event.currentTarget.dataset.modalId
    const modal = document.getElementById(modalId)
    if (modal) {
      modal.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    }
  }

  close() {
    const container = this.element.closest("[data-modal-container]")
    if (container) {
      container.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }
}
