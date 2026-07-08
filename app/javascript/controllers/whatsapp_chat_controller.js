import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["messages", "input", "form", "search", "conversationList"]

  connect() {
    this.consumer = createConsumer()
    this.scrollToBottom()
    this.observeNewMessages()
    this.subscribeToConversationList()

    const conversationId = this.messagesTarget?.dataset?.conversationId
    if (conversationId) {
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
      if (input.value.trim() !== "") {
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
}
