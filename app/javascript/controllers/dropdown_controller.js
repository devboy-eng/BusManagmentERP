import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "arrow"]

  connect() {
    // Auto-open if a child link is active (only for sidebar nav dropdowns)
    if (this.hasArrowTarget) {
      const activeLink = this.menuTarget.querySelector(".text-indigo-600, .text-indigo-400")
      if (activeLink) {
        this.menuTarget.classList.remove("hidden")
        this.arrowTarget.classList.add("rotate-180")
      }
    }
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    if (this.hasArrowTarget) {
      this.arrowTarget.classList.toggle("rotate-180")
    }
  }
}
