import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "templateTypeRadio",
    "standardFields",
    "carouselFields",
    "headerTypeSelect",
    "headerTextField",
    "headerMediaField",
    "previewHeader",
    "previewBody",
    "previewFooter",
    "previewMediaPlaceholder",
    "previewStandardBubble",
    "previewCarouselWrap",
    "previewCarouselCards",
    "previewCarouselBody",
    "previewCarouselFooter",
    "bodyInput",
    "footerInput",
    "headerTextInput",
    "headerMediaInput",
    "cardsContainer",
    "carouselCardsInput"
  ]

  connect() {
    this.updatePreview()
    this.headerTypeChanged()
    this.syncTemplateTypeUI()
  }

  syncTemplateTypeUI() {
    const checked = this.templateTypeRadioTargets.find(r => r.checked)
    if (checked) {
      this.toggleTemplateType(checked.value)
    }
  }

  selectTemplateType(event) {
    const type = event.currentTarget.dataset.templateType
    this.toggleTemplateType(type)
    this.updatePreview()
  }

  toggleTemplateType(type) {
    if (this.hasStandardFieldsTarget) {
      this.standardFieldsTarget.classList.toggle("hidden", type === "carousel")
    }
    if (this.hasCarouselFieldsTarget) {
      this.carouselFieldsTarget.classList.toggle("hidden", type !== "carousel")
    }
    if (this.hasPreviewCarouselWrapTarget) {
      this.previewCarouselWrapTarget.classList.toggle("hidden", type !== "carousel")
    }
    if (this.hasPreviewStandardBubbleTarget) {
      this.previewStandardBubbleTarget.classList.toggle("hidden", type === "carousel")
    }
  }

  headerTypeChanged() {
    if (!this.hasHeaderTypeSelectTarget) return
    const type = this.headerTypeSelectTarget.value

    if (this.hasHeaderTextFieldTarget) {
      this.headerTextFieldTarget.classList.toggle("hidden", type !== "text")
    }
    if (this.hasHeaderMediaFieldTarget) {
      this.headerMediaFieldTarget.classList.toggle("hidden", !["image", "video", "document"].includes(type))
    }

    this.updatePreview()
  }

  // --- Carousel card management ---

  addCard() {
    const container = this.cardsContainerTarget
    const index = container.querySelectorAll(".carousel-card").length

    if (index >= 10) return

    const cardHtml = `
      <div class="carousel-card rounded-lg border border-gray-200 bg-gray-50 p-4 space-y-3" data-card-index="${index}">
        <div class="flex items-center justify-between">
          <span class="text-xs font-semibold text-gray-700">Card ${index + 1}</span>
          <button type="button" data-action="template-form#removeCard" class="text-red-500 hover:text-red-600 transition">
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>
        <div data-controller="image-upload">
          <label class="block text-[11px] font-medium text-gray-600 mb-1">Card Image</label>
          <div class="flex gap-2">
            <input type="text" class="card-image-url flex-1 rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none" placeholder="https://example.com/image.jpg" data-action="input->template-form#updateCarouselData" data-image-upload-target="urlInput">
            <button type="button" data-action="image-upload#pick" data-image-upload-target="uploadBtn" class="inline-flex items-center gap-1 rounded-lg bg-gray-100 px-2.5 py-2 text-[11px] font-medium text-gray-700 hover:bg-gray-200 transition whitespace-nowrap">
              <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" /></svg>
              Upload
            </button>
            <input type="file" accept="image/*" class="hidden" data-image-upload-target="fileInput" data-action="image-upload#upload">
          </div>
          <div class="hidden mt-1.5 h-16 w-16 rounded border border-gray-200 overflow-hidden" data-image-upload-target="preview"></div>
        </div>
        <div>
          <label class="block text-[11px] font-medium text-gray-600 mb-1">Card Body</label>
          <textarea class="card-body w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none" rows="2" placeholder="Card description text" data-action="input->template-form#updateCarouselData"></textarea>
        </div>
        <div>
          <label class="block text-[11px] font-medium text-gray-600 mb-1">Button Text <span class="text-gray-400 font-normal">(Optional)</span></label>
          <input type="text" class="card-button-text w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none" placeholder="e.g. View Details" data-action="input->template-form#updateCarouselData">
        </div>
        <div>
          <label class="block text-[11px] font-medium text-gray-600 mb-1">Button URL <span class="text-gray-400 font-normal">(Optional)</span></label>
          <input type="text" class="card-button-url w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none" placeholder="https://example.com/page" data-action="input->template-form#updateCarouselData">
        </div>
      </div>
    `

    container.insertAdjacentHTML("beforeend", cardHtml)
    this.updateCarouselData()
    this.renumberCards()
    this.updatePreview()
  }

  removeCard(event) {
    const card = event.currentTarget.closest(".carousel-card")
    card.remove()
    this.renumberCards()
    this.updateCarouselData()
    this.updatePreview()
  }

  renumberCards() {
    const cards = this.cardsContainerTarget.querySelectorAll(".carousel-card")
    cards.forEach((card, i) => {
      card.dataset.cardIndex = i
      const label = card.querySelector("span.text-xs.font-semibold")
      if (label) label.textContent = `Card ${i + 1}`
    })
  }

  updateCarouselData() {
    if (!this.hasCarouselCardsInputTarget) return

    const cards = this.cardsContainerTarget.querySelectorAll(".carousel-card")
    const data = Array.from(cards).map(card => ({
      image_url: card.querySelector(".card-image-url")?.value || "",
      body: card.querySelector(".card-body")?.value || "",
      button_text: card.querySelector(".card-button-text")?.value || "",
      button_url: card.querySelector(".card-button-url")?.value || ""
    }))

    this.carouselCardsInputTarget.value = JSON.stringify(data)
    this.updatePreview()
  }

  // --- Preview ---

  updatePreview() {
    const checked = this.templateTypeRadioTargets.find(r => r.checked)
    const templateType = checked ? checked.value : "standard"

    if (templateType === "carousel") {
      this.updateCarouselPreview()
    } else {
      this.updateStandardPreview()
    }

    // Standard body + footer
    if (this.hasPreviewBodyTarget && this.hasBodyInputTarget) {
      this.previewBodyTarget.textContent = this.bodyInputTarget.value || "Message body will appear here..."
    }
    if (this.hasPreviewFooterTarget && this.hasFooterInputTarget) {
      const footerText = this.footerInputTarget.value
      this.previewFooterTarget.textContent = footerText
      this.previewFooterTarget.classList.toggle("hidden", !footerText)
    }

    // Carousel body + footer
    if (this.hasPreviewCarouselBodyTarget && this.hasBodyInputTarget) {
      this.previewCarouselBodyTarget.textContent = this.bodyInputTarget.value || "Message body will appear here..."
    }
    if (this.hasPreviewCarouselFooterTarget && this.hasFooterInputTarget) {
      const footerText = this.footerInputTarget.value
      this.previewCarouselFooterTarget.textContent = footerText
      this.previewCarouselFooterTarget.classList.toggle("hidden", !footerText)
    }
  }

  updateStandardPreview() {
    const headerType = this.hasHeaderTypeSelectTarget ? this.headerTypeSelectTarget.value : "none"

    if (this.hasPreviewHeaderTarget) {
      if (headerType === "text" && this.hasHeaderTextInputTarget) {
        this.previewHeaderTarget.textContent = this.headerTextInputTarget.value || "Header text"
        this.previewHeaderTarget.classList.remove("hidden")
      } else if (headerType === "none") {
        this.previewHeaderTarget.classList.add("hidden")
      } else {
        this.previewHeaderTarget.textContent = ""
        this.previewHeaderTarget.classList.add("hidden")
      }
    }

    if (this.hasPreviewMediaPlaceholderTarget) {
      if (["image", "video", "document"].includes(headerType)) {
        const icons = { image: "Image", video: "Video", document: "Document" }
        this.previewMediaPlaceholderTarget.textContent = icons[headerType] || ""
        this.previewMediaPlaceholderTarget.classList.remove("hidden")
      } else {
        this.previewMediaPlaceholderTarget.classList.add("hidden")
      }
    }
  }

  updateCarouselPreview() {
    if (!this.hasPreviewCarouselCardsTarget) return

    // Read card data from DOM inputs directly
    let cardsData = []
    if (this.hasCardsContainerTarget) {
      const cards = this.cardsContainerTarget.querySelectorAll(".carousel-card")
      cardsData = Array.from(cards).map(card => ({
        image_url: card.querySelector(".card-image-url")?.value || "",
        body: card.querySelector(".card-body")?.value || "",
        button_text: card.querySelector(".card-button-text")?.value || "",
        button_url: card.querySelector(".card-button-url")?.value || ""
      }))
    }

    // Fallback to hidden field JSON
    if (cardsData.length === 0) {
      try {
        if (this.hasCarouselCardsInputTarget && this.carouselCardsInputTarget.value) {
          cardsData = JSON.parse(this.carouselCardsInputTarget.value)
        }
      } catch(e) { /* ignore */ }
    }

    const container = this.previewCarouselCardsTarget
    container.innerHTML = ""

    if (cardsData.length === 0) {
      container.innerHTML = `
        <div class="w-full py-6 text-center">
          <svg class="h-5 w-5 text-gray-300 mx-auto mb-1.5" fill="none" viewBox="0 0 24 24" stroke-width="1" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 6.878V6a2.25 2.25 0 012.25-2.25h7.5A2.25 2.25 0 0118 6v.878m-12 0c.235-.083.487-.128.75-.128h10.5c.263 0 .515.045.75.128m-12 0A2.25 2.25 0 004.5 9v.878m13.5-3A2.25 2.25 0 0119.5 9v.878m0 0a2.246 2.246 0 00-.75-.128H5.25c-.263 0-.515.045-.75.128m15 0A2.25 2.25 0 0121 12v6a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 18v-6c0-1.013.67-1.871 1.59-2.154" /></svg>
          <p class="text-[11px] text-gray-400">Add cards to see carousel preview</p>
        </div>
      `
      return
    }

    cardsData.forEach((card, i) => {
      const cardEl = document.createElement("div")
      cardEl.className = "flex-shrink-0 rounded-lg overflow-hidden shadow"
      cardEl.style.backgroundColor = "#DCF8C6"
      cardEl.style.width = "calc(100% - 16px)"

      const placeholderDisplay = card.image_url ? "display:none;" : ""

      const buttonHtml = card.button_text
        ? `<div style="border-top: 1px solid rgba(0,0,0,0.08);"><div class="py-2 text-center"><span class="text-[12px] font-medium" style="color: #00A5F4;">${this.escapeHtml(card.button_text)}</span></div></div>`
        : ""

      const imgTag = card.image_url
        ? `<img src="${this.escapeHtml(card.image_url)}" style="position:absolute;top:0;left:0;width:100%;height:100%;object-fit:cover;" onerror="this.style.display='none';this.nextElementSibling.style.display=''">`
        : ""

      cardEl.innerHTML = `
        <div style="position:relative;height:140px;background:#C5E8B0;overflow:hidden;">
          ${imgTag}
          <div style="display:flex;align-items:center;justify-content:center;height:100%;${placeholderDisplay}">
            <svg style="height:32px;width:32px;color:#8BC88A;" fill="none" viewBox="0 0 24 24" stroke-width="1" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21z" /></svg>
          </div>
        </div>
        <div class="px-2.5 py-2">
          <p class="text-[12px] text-gray-900 leading-[1.35] line-clamp-3">${this.escapeHtml(card.body || `Card ${i + 1} body`)}</p>
        </div>
        ${buttonHtml}
      `
      container.appendChild(cardEl)
    })
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
