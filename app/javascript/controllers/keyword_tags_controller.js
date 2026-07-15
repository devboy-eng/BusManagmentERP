import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenField", "tagsContainer"]

  connect() {
    this.renderTags()
  }

  getTags() {
    const val = this.hiddenFieldTarget.value || ""
    return val.split(",").map(t => t.trim()).filter(t => t.length > 0)
  }

  setTags(tags) {
    this.hiddenFieldTarget.value = tags.join(", ")
    this.renderTags()
  }

  renderTags() {
    const tags = this.getTags()
    const container = this.tagsContainerTarget

    // Remove existing tag elements (keep only the input)
    container.querySelectorAll("[data-tag]").forEach(el => el.remove())

    // Insert tags before the input
    tags.forEach((tag, index) => {
      const tagEl = document.createElement("span")
      tagEl.setAttribute("data-tag", "true")
      tagEl.className = "inline-flex items-center gap-1 rounded-md bg-indigo-50 border border-indigo-200 px-2 py-0.5 text-xs font-medium text-indigo-700"
      tagEl.innerHTML = `
        ${this.escapeHtml(tag)}
        <button type="button" data-index="${index}" data-action="keyword-tags#removeTag" class="text-indigo-400 hover:text-red-500 transition ml-0.5">
          <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
        </button>
      `
      container.insertBefore(tagEl, this.inputTarget)
    })
  }

  handleKeydown(event) {
    const input = this.inputTarget
    const value = input.value.trim()

    // Enter or comma to add tag
    if (event.key === "Enter" || event.key === ",") {
      event.preventDefault()
      if (value.length > 0) {
        this.addTag(value)
        input.value = ""
      }
      return
    }

    // Backspace on empty input removes last tag
    if (event.key === "Backspace" && input.value === "") {
      const tags = this.getTags()
      if (tags.length > 0) {
        tags.pop()
        this.setTags(tags)
      }
    }
  }

  // Also handle paste with commas
  handleInput(event) {
    const input = this.inputTarget
    const value = input.value

    if (value.includes(",")) {
      const parts = value.split(",").map(t => t.trim()).filter(t => t.length > 0)
      parts.forEach(p => this.addTag(p))
      input.value = ""
    }
  }

  addTag(text) {
    const tag = text.replace(/,/g, "").trim()
    if (tag.length === 0) return

    const tags = this.getTags()
    // Avoid duplicates (case-insensitive)
    if (tags.some(t => t.toLowerCase() === tag.toLowerCase())) return

    tags.push(tag)
    this.setTags(tags)
  }

  removeTag(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.index)
    const tags = this.getTags()
    tags.splice(index, 1)
    this.setTags(tags)
  }

  // Focus input when clicking the container
  focusInput() {
    this.inputTarget.focus()
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
