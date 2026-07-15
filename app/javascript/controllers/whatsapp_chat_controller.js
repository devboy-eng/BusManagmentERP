import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [
    "messages", "input", "form", "search", "conversationList",
    "fileInput", "filePreview", "fileName",
    "quickResponseDropdown",
    "scheduleModal", "scheduleBody", "scheduleAt",
    "searchBar", "messageSearch", "searchResults",
    "globalSearchPanel", "globalSearchInput", "globalSearchResults"
  ]

  connect() {
    this.consumer = createConsumer()
    this.scrollToBottom()
    this.observeNewMessages()
    this.subscribeToConversationList()
    this.selectedFile = null
    this.searchTimeout = null
    this.quickResponseTimeout = null

    const conversationId = this.messagesTarget?.dataset?.conversationId
    if (conversationId) {
      this.currentConversationId = conversationId
      this.subscribeToConversation(conversationId)
    }
  }

  disconnect() {
    if (this.conversationSubscription) this.conversationSubscription.unsubscribe()
    if (this.listSubscription) this.listSubscription.unsubscribe()
    if (this.observer) this.observer.disconnect()
    if (this.consumer) this.consumer.disconnect()
  }

  subscribeToConversation(conversationId) {
    if (this.conversationSubscription) this.conversationSubscription.unsubscribe()

    const controller = this
    this.conversationSubscription = this.consumer.subscriptions.create(
      { channel: "WhatsappChatChannel", conversation_id: conversationId },
      {
        received(data) {
          if (data.type === "new_message") {
            const container = controller.messagesTarget
            if (container) {
              container.insertAdjacentHTML("beforeend", data.html)
              controller.scrollToBottom()
            }
          } else if (data.type === "message_status") {
            const existing = document.getElementById(`message-${data.message_id}`)
            if (existing) {
              existing.outerHTML = data.html
            }
          }
        }
      }
    )
  }

  subscribeToConversationList() {
    const controller = this
    this.listSubscription = this.consumer.subscriptions.create(
      { channel: "WhatsappChatChannel" },
      {
        received(data) {
          if (data.type === "conversation_update" && controller.hasConversationListTarget) {
            const list = controller.conversationListTarget
            const existing = list.querySelector(`[data-conversation-id="${data.conversation_id}"]`)
            if (existing) {
              const parent = existing.closest("a")
              if (parent) parent.outerHTML = data.html
            } else {
              list.insertAdjacentHTML("afterbegin", data.html)
            }
          }
        }
      }
    )
  }

  observeNewMessages() {
    if (!this.hasMessagesTarget) return

    this.observer = new MutationObserver(() => {
      this.scrollToBottom()
    })

    this.observer.observe(this.messagesTarget, { childList: true })
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      const input = this.inputTarget
      if (input.value.trim() !== "" || this.selectedFile) {
        this.formTarget.requestSubmit()
      }
    }
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 120) + "px"
  }

  filterConversations() {
    const query = this.searchTarget.value.toLowerCase()
    const items = this.conversationListTarget.querySelectorAll("a[data-conversation-id]")

    items.forEach(item => {
      const text = item.textContent.toLowerCase()
      item.style.display = text.includes(query) ? "" : "none"
    })
  }

  // --- File Attachment ---

  triggerFileInput() {
    if (this.hasFileInputTarget) {
      this.fileInputTarget.click()
    }
  }

  handleFileSelected() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    this.selectedFile = file
    if (this.hasFilePreviewTarget) {
      this.filePreviewTarget.classList.remove("hidden")
      this.fileNameTarget.textContent = `${file.name} (${(file.size / 1024).toFixed(1)} KB)`
    }
  }

  removeFile() {
    this.selectedFile = null
    this.fileInputTarget.value = ""
    if (this.hasFilePreviewTarget) {
      this.filePreviewTarget.classList.add("hidden")
    }
  }

  // --- Quick Response Autocomplete ---

  checkQuickResponse() {
    if (!this.hasInputTarget || !this.hasQuickResponseDropdownTarget) return

    const value = this.inputTarget.value
    if (value.startsWith("/") && value.length > 1) {
      clearTimeout(this.quickResponseTimeout)
      this.quickResponseTimeout = setTimeout(() => {
        this.fetchQuickResponses(value)
      }, 200)
    } else {
      this.quickResponseDropdownTarget.classList.add("hidden")
    }
  }

  async fetchQuickResponses(query) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(`/quick_responses.json?q=${encodeURIComponent(query)}`)
      if (!response.ok) return

      const data = await response.json()
      if (data.length === 0) {
        this.quickResponseDropdownTarget.classList.add("hidden")
        return
      }

      this.quickResponseDropdownTarget.innerHTML = data.map(qr =>
        `<button type="button" class="w-full text-left px-3 py-2 hover:bg-gray-50 transition border-b border-gray-100 last:border-0" data-action="click->whatsapp-chat#selectQuickResponse" data-body="${this.escapeHtml(qr.body)}">
          <p class="text-xs font-medium text-gray-900">${this.escapeHtml(qr.title)}</p>
          <p class="text-[11px] text-gray-500 truncate">${this.escapeHtml(qr.body.substring(0, 60))}</p>
          ${qr.shortcode ? `<span class="text-[10px] text-indigo-500">${this.escapeHtml(qr.shortcode)}</span>` : ''}
        </button>`
      ).join("")

      this.quickResponseDropdownTarget.classList.remove("hidden")
    } catch (err) {
      console.error("Failed to fetch quick responses:", err)
    }
  }

  selectQuickResponse(event) {
    const body = event.currentTarget.dataset.body
    this.inputTarget.value = body
    this.quickResponseDropdownTarget.classList.add("hidden")
    this.inputTarget.focus()
    this.autoResize()
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }

  // --- Schedule Message ---

  toggleScheduleModal() {
    if (!this.hasScheduleModalTarget) return
    this.scheduleModalTarget.classList.toggle("hidden")
  }

  async submitSchedule() {
    if (!this.hasScheduleBodyTarget || !this.hasScheduleAtTarget) return

    const body = this.scheduleBodyTarget.value.trim()
    const scheduledAt = this.scheduleAtTarget.value

    if (!body || !scheduledAt) {
      alert("Please enter both a message and scheduled time.")
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const conversationId = this.currentConversationId

    try {
      const response = await fetch(`/whatsapp_chats/${conversationId}/schedule_message`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          message_body: body,
          scheduled_at: scheduledAt
        })
      })

      const data = await response.json()
      if (response.ok) {
        this.scheduleBodyTarget.value = ""
        this.scheduleAtTarget.value = ""
        this.toggleScheduleModal()
        alert("Message scheduled successfully!")
      } else {
        alert("Failed to schedule: " + (data.error || "Unknown error"))
      }
    } catch (err) {
      console.error("Schedule failed:", err)
      alert("Failed to schedule message.")
    }
  }

  // --- Chat Search ---

  toggleSearch() {
    if (!this.hasSearchBarTarget) return
    this.searchBarTarget.classList.toggle("hidden")
    if (!this.searchBarTarget.classList.contains("hidden") && this.hasMessageSearchTarget) {
      this.messageSearchTarget.focus()
    }
  }

  searchMessages() {
    if (!this.hasMessageSearchTarget || !this.hasMessagesTarget) return

    const query = this.messageSearchTarget.value.toLowerCase()
    const messages = this.messagesTarget.querySelectorAll("[data-message-id]")

    if (query === "") {
      messages.forEach(msg => {
        msg.style.opacity = ""
        msg.style.border = ""
      })
      if (this.hasSearchResultsTarget) this.searchResultsTarget.classList.add("hidden")
      return
    }

    let matchCount = 0
    messages.forEach(msg => {
      const text = msg.textContent.toLowerCase()
      if (text.includes(query)) {
        msg.style.opacity = ""
        msg.style.border = "2px solid #6366f1"
        msg.style.borderRadius = "8px"
        matchCount++
      } else {
        msg.style.opacity = "0.3"
        msg.style.border = ""
      }
    })

    if (this.hasSearchResultsTarget) {
      this.searchResultsTarget.classList.remove("hidden")
      this.searchResultsTarget.innerHTML = `<p class="text-[11px] text-gray-500">${matchCount} match${matchCount !== 1 ? 'es' : ''} found</p>`
    }
  }

  // --- Global Message Search ---

  searchAllMessages() {
    if (!this.hasGlobalSearchPanelTarget) return
    this.globalSearchPanelTarget.classList.toggle("hidden")
    if (!this.globalSearchPanelTarget.classList.contains("hidden") && this.hasGlobalSearchInputTarget) {
      this.globalSearchInputTarget.focus()
    }
  }

  performGlobalSearch() {
    if (!this.hasGlobalSearchInputTarget || !this.hasGlobalSearchResultsTarget) return

    clearTimeout(this.searchTimeout)
    const query = this.globalSearchInputTarget.value.trim()

    if (query.length < 2) {
      this.globalSearchResultsTarget.innerHTML = ""
      return
    }

    this.searchTimeout = setTimeout(async () => {
      try {
        const response = await fetch(`/whatsapp_chats/search.json?q=${encodeURIComponent(query)}`)
        if (!response.ok) return

        const data = await response.json()
        if (data.results.length === 0) {
          this.globalSearchResultsTarget.innerHTML = '<p class="text-[11px] text-gray-400 py-2">No results found.</p>'
          return
        }

        this.globalSearchResultsTarget.innerHTML = data.results.map(r =>
          `<a href="/whatsapp_chats/${r.conversation_id}" class="block px-2 py-1.5 rounded hover:bg-white transition">
            <p class="text-[11px] font-medium text-gray-900">${this.escapeHtml(r.conversation_name || 'Unknown')}</p>
            <p class="text-[11px] text-gray-500 truncate">${this.escapeHtml(r.body || '')}</p>
            <p class="text-[10px] text-gray-400">${r.direction === 'incoming' ? 'Received' : 'Sent'} &middot; ${r.created_at}</p>
          </a>`
        ).join("")
      } catch (err) {
        console.error("Global search failed:", err)
      }
    }, 300)
  }
}
