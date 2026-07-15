import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { messageId: Number, conversationId: Number }

  showPicker(event) {
    event.stopPropagation()

    // Remove any existing picker
    const existing = document.getElementById("emoji-reaction-picker")
    if (existing) {
      existing.remove()
      return
    }

    const emojis = ["\u{1F44D}", "\u{2764\uFE0F}", "\u{1F602}", "\u{1F62E}", "\u{1F622}", "\u{1F64F}"]
    const picker = document.createElement("div")
    picker.id = "emoji-reaction-picker"
    picker.className = "absolute z-50 bg-white border border-gray-200 rounded-full shadow-lg px-2 py-1 flex items-center gap-1"
    picker.style.bottom = "100%"
    picker.style.right = "0"
    picker.style.marginBottom = "4px"

    emojis.forEach(emoji => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "text-lg hover:scale-125 transition-transform cursor-pointer p-0.5"
      btn.textContent = emoji
      btn.addEventListener("click", () => {
        this.sendReaction(emoji)
        picker.remove()
      })
      picker.appendChild(btn)
    })

    this.element.style.position = "relative"
    this.element.appendChild(picker)

    // Close on outside click
    const closePicker = (e) => {
      if (!picker.contains(e.target)) {
        picker.remove()
        document.removeEventListener("click", closePicker)
      }
    }
    setTimeout(() => document.addEventListener("click", closePicker), 0)
  }

  async sendReaction(emoji) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(`/whatsapp_chats/${this.conversationIdValue}/react`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          message_id: this.messageIdValue,
          emoji: emoji
        })
      })

      if (!response.ok) {
        const data = await response.json()
        console.error("Reaction failed:", data.error)
      }
    } catch (err) {
      console.error("Reaction request failed:", err)
    }
  }
}
