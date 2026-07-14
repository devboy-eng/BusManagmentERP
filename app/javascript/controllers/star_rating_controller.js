import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "star"]

  select(event) {
    const value = parseInt(event.currentTarget.dataset.value)
    this.inputTarget.value = value

    this.starTargets.forEach((star, index) => {
      const svg = star.querySelector("svg")
      if (index < value) {
        svg.classList.remove("text-gray-300")
        svg.classList.add("text-yellow-400")
      } else {
        svg.classList.remove("text-yellow-400")
        svg.classList.add("text-gray-300")
      }
    })
  }
}
