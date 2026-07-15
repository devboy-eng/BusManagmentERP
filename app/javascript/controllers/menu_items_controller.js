import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "item", "hiddenField", "addButton"]

  connect() {
    this.syncHiddenField()
  }

  add(event) {
    event.preventDefault()

    const items = this.containerTarget.querySelectorAll("[data-menu-items-target='item']")
    if (items.length >= 10) {
      alert("Maximum 10 items allowed")
      return
    }

    const id = Math.random().toString(36).substring(2, 10)
    const html = `
      <div class="rounded-lg border border-gray-200 bg-gray-50 p-4 relative" data-menu-items-target="item">
        <button type="button" data-action="menu-items#remove" class="absolute top-2 right-2 text-gray-400 hover:text-red-500 transition" title="Remove item">
          <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
        </button>
        <div class="grid grid-cols-2 gap-3 mb-3">
          <div>
            <label class="block text-[11px] font-medium text-gray-600 mb-1">Title <span class="text-red-400">*</span></label>
            <input type="text" data-field="title" value="" maxlength="24" class="w-full rounded-lg border border-gray-300 px-3 py-1.5 text-xs focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none" placeholder="e.g. Check Balance">
          </div>
          <div>
            <label class="block text-[11px] font-medium text-gray-600 mb-1">Description (optional)</label>
            <input type="text" data-field="description" value="" maxlength="72" class="w-full rounded-lg border border-gray-300 px-3 py-1.5 text-xs focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none" placeholder="Short description">
          </div>
        </div>
        <div>
          <label class="block text-[11px] font-medium text-gray-600 mb-1">Reply Text <span class="text-red-400">*</span></label>
          <textarea data-field="reply_text" rows="2" class="w-full rounded-lg border border-gray-300 px-3 py-1.5 text-xs focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none" placeholder="Reply sent when customer selects this item..."></textarea>
        </div>
      </div>
    `

    this.containerTarget.insertAdjacentHTML("beforeend", html)
    this.updateAddButton()
    this.syncHiddenField()
  }

  remove(event) {
    event.preventDefault()

    const items = this.containerTarget.querySelectorAll("[data-menu-items-target='item']")
    if (items.length <= 1) {
      alert("At least 1 item is required")
      return
    }

    const item = event.target.closest("[data-menu-items-target='item']")
    if (item) {
      item.remove()
      this.updateAddButton()
      this.syncHiddenField()
    }
  }

  updateAddButton() {
    const items = this.containerTarget.querySelectorAll("[data-menu-items-target='item']")
    if (this.hasAddButtonTarget) {
      this.addButtonTarget.style.display = items.length >= 10 ? "none" : ""
    }
  }

  syncHiddenField() {
    const items = this.containerTarget.querySelectorAll("[data-menu-items-target='item']")
    const data = Array.from(items).map((item, index) => {
      const title = item.querySelector("[data-field='title']")?.value || ""
      const description = item.querySelector("[data-field='description']")?.value || ""
      const replyText = item.querySelector("[data-field='reply_text']")?.value || ""
      return {
        id: `item_${index + 1}`,
        title: title,
        description: description,
        reply_text: replyText
      }
    })

    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = JSON.stringify(data)
    }
  }

  // Sync on any input change within the form
  containerTargetConnected() {
    this.containerTarget.addEventListener("input", () => this.syncHiddenField())
  }
}
