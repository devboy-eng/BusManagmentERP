import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "bg", "dot"]

  toggle() {
    const checked = !this.checkboxTarget.checked
    this.checkboxTarget.checked = checked

    if (checked) {
      this.bgTarget.classList.add("bg-indigo-600")
      this.bgTarget.classList.remove("bg-gray-200")
      this.dotTarget.classList.add("translate-x-5")
      this.dotTarget.classList.remove("translate-x-0")
    } else {
      this.bgTarget.classList.remove("bg-indigo-600")
      this.bgTarget.classList.add("bg-gray-200")
      this.dotTarget.classList.remove("translate-x-5")
      this.dotTarget.classList.add("translate-x-0")
    }
  }
}
