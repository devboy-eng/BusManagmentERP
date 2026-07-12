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
    "carouselCardsInput",
    "buttonsContainer",
    "buttonsInput",
    "buttonMixWarning",
    "buttonsSection",
    "previewButtons"
  ]

  connect() {
    this.updatePreview()
    this.headerTypeChanged()
    this.syncTemplateTypeUI()
    this.checkButtonMixing()
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
    if (this.hasButtonsSectionTarget) {
      this.buttonsSectionTarget.classList.toggle("hidden", type === "carousel")
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

  // --- Button management (standard templates) ---

  addButton(event) {
    try {
      const type = event.currentTarget.dataset.buttonType
      if (!type) return

      const container = this.buttonsContainerTarget
      const existingButtons = container.querySelectorAll(".button-row")
      const count = existingButtons.length

      // Enforce limits
      const types = Array.from(existingButtons).map(r => r.dataset.buttonType)
      const hasQR = types.includes("QUICK_REPLY")
      const hasCTA = types.some(t => ["URL", "PHONE_NUMBER", "COPY_CODE"].includes(t))
      const ctaTypes = ["URL", "PHONE_NUMBER", "COPY_CODE"]

      // No mixing
      if (type === "QUICK_REPLY" && hasCTA) { this.checkButtonMixing(); return }
      if (ctaTypes.includes(type) && hasQR) { this.checkButtonMixing(); return }

      // Max 10 QR, max 2 CTA
      if (type === "QUICK_REPLY" && types.filter(t => t === "QUICK_REPLY").length >= 10) return
      if (ctaTypes.includes(type) && types.filter(t => ctaTypes.includes(t)).length >= 2) return

      const typeLabel = type.replace(/_/g, " ")
      let extraFields = ""
      if (type === "URL") {
        extraFields = `<input type="text" class="btn-url w-full rounded-lg border border-gray-300 bg-white px-2.5 py-1.5 text-[11px] text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none" placeholder="https://example.com/{{1}}" data-action="input->template-form#updateButtonsData">`
      } else if (type === "PHONE_NUMBER") {
        extraFields = `<input type="text" class="btn-phone w-full rounded-lg border border-gray-300 bg-white px-2.5 py-1.5 text-[11px] text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none" placeholder="+919876543210" data-action="input->template-form#updateButtonsData">`
      }

      const rowHtml = `
        <div class="button-row rounded-lg border border-gray-200 bg-gray-50 p-2.5 space-y-1.5" data-button-type="${type}">
          <div class="flex items-center justify-between">
            <span class="inline-flex items-center rounded bg-gray-200 px-1.5 py-0.5 text-[10px] font-medium text-gray-600 whitespace-nowrap">${this.escapeHtml(typeLabel)}</span>
            <button type="button" data-action="template-form#removeButton" class="text-red-400 hover:text-red-600 transition">
              <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>
          <input type="text" class="btn-text w-full rounded-lg border border-gray-300 bg-white px-2.5 py-1.5 text-[11px] text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none" placeholder="Button text (max 25)" maxlength="25" data-action="input->template-form#updateButtonsData">
          ${extraFields}
        </div>
      `

      container.insertAdjacentHTML("beforeend", rowHtml)
      this.updateButtonsData()
      this.checkButtonMixing()
      this.renderButtonsPreview()
    } catch(e) {
      console.error("addButton error:", e)
    }
  }

  removeButton(event) {
    const row = event.currentTarget.closest(".button-row")
    row.remove()
    this.updateButtonsData()
    this.checkButtonMixing()
  }

  updateButtonsData() {
    if (!this.hasButtonsInputTarget) return

    const rows = this.buttonsContainerTarget.querySelectorAll(".button-row")
    const buttons = Array.from(rows).map(row => {
      const type = row.dataset.buttonType
      const btn = {
        type: type,
        text: row.querySelector(".btn-text")?.value || ""
      }
      if (type === "URL") {
        btn.url = row.querySelector(".btn-url")?.value || ""
      }
      if (type === "PHONE_NUMBER") {
        btn.phone_number = row.querySelector(".btn-phone")?.value || ""
      }
      return btn
    })

    this.buttonsInputTarget.value = JSON.stringify(buttons)
    this.updatePreview()
  }

  checkButtonMixing() {
    if (!this.hasButtonMixWarningTarget || !this.hasButtonsContainerTarget) return

    const rows = this.buttonsContainerTarget.querySelectorAll(".button-row")
    const types = Array.from(rows).map(r => r.dataset.buttonType)
    const hasQR = types.includes("QUICK_REPLY")
    const hasCTA = types.some(t => ["URL", "PHONE_NUMBER", "COPY_CODE"].includes(t))

    this.buttonMixWarningTarget.classList.toggle("hidden", !(hasQR && hasCTA))
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
        <div class="space-y-2">
          <div class="flex items-center justify-between">
            <label class="block text-[11px] font-medium text-gray-600">Buttons <span class="text-gray-400 font-normal">(max 2)</span></label>
            <select class="card-add-button rounded border border-gray-300 bg-white px-2 py-1 text-[10px] text-gray-600 focus:border-indigo-500 focus:outline-none" data-action="change->template-form#addCardButton">
              <option value="">+ Add button</option>
              <option value="QUICK_REPLY">Quick Reply</option>
              <option value="URL">URL</option>
              <option value="PHONE_NUMBER">Phone Number</option>
            </select>
          </div>
          <div class="card-buttons-container space-y-1.5"></div>
        </div>
      </div>
    `

    container.insertAdjacentHTML("beforeend", cardHtml)
    this.updateCarouselData()
    this.renumberCards()
    this.updatePreview()
  }

  addCardButton(event) {
    const select = event.currentTarget
    const type = select.value
    if (!type) return

    select.value = ""

    const card = select.closest(".carousel-card")
    const btnContainer = card.querySelector(".card-buttons-container")
    const existing = btnContainer.querySelectorAll(".card-button-row").length
    if (existing >= 2) return

    const typeLabels = { "URL": "URL", "QUICK_REPLY": "QR", "PHONE_NUMBER": "Phone" }
    const typeLabel = typeLabels[type] || type
    let extraField = ""
    if (type === "URL") {
      extraField = `<input type="text" class="card-btn-url flex-1 rounded border border-gray-300 bg-white px-2 py-1 text-[11px] text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:outline-none" placeholder="https://..." data-action="input->template-form#updateCarouselData">`
    } else if (type === "PHONE_NUMBER") {
      extraField = `<input type="text" class="card-btn-phone flex-1 rounded border border-gray-300 bg-white px-2 py-1 text-[11px] text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:outline-none" placeholder="+919876543210" data-action="input->template-form#updateCarouselData">`
    }

    const rowHtml = `
      <div class="card-button-row flex items-center gap-1.5" data-button-type="${type}">
        <span class="text-[9px] font-medium text-gray-500 w-8 shrink-0">${typeLabel}</span>
        <input type="text" class="card-btn-text flex-1 rounded border border-gray-300 bg-white px-2 py-1 text-[11px] text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:outline-none" placeholder="Button text" maxlength="25" data-action="input->template-form#updateCarouselData">
        ${extraField}
        <button type="button" data-action="template-form#removeCardButton" class="text-red-400 hover:text-red-600">
          <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
        </button>
      </div>
    `

    btnContainer.insertAdjacentHTML("beforeend", rowHtml)
    this.updateCarouselData()
  }

  removeCardButton(event) {
    const row = event.currentTarget.closest(".card-button-row")
    row.remove()
    this.updateCarouselData()
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
    const data = Array.from(cards).map(card => {
      const cardData = {
        image_url: card.querySelector(".card-image-url")?.value || "",
        body: card.querySelector(".card-body")?.value || ""
      }

      // Read buttons from card-button-rows
      const btnRows = card.querySelectorAll(".card-button-row")
      if (btnRows.length > 0) {
        cardData.buttons = Array.from(btnRows).map(row => {
          const btn = {
            type: row.dataset.buttonType,
            text: row.querySelector(".card-btn-text")?.value || ""
          }
          if (row.dataset.buttonType === "URL") {
            btn.url = row.querySelector(".card-btn-url")?.value || ""
          }
          if (row.dataset.buttonType === "PHONE_NUMBER") {
            btn.phone_number = row.querySelector(".card-btn-phone")?.value || ""
          }
          return btn
        })
      }

      return cardData
    })

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

    // Render buttons preview
    this.renderButtonsPreview()
  }

  renderButtonsPreview() {
    if (!this.hasPreviewButtonsTarget) return

    let buttons = []
    try {
      if (this.hasButtonsInputTarget && this.buttonsInputTarget.value) {
        buttons = JSON.parse(this.buttonsInputTarget.value)
      }
    } catch(e) { /* ignore */ }

    const container = this.previewButtonsTarget
    container.innerHTML = ""

    if (!buttons.length) return

    const hasQR = buttons.some(b => b.type === "QUICK_REPLY")

    if (hasQR) {
      // Quick Reply: horizontal row of rounded buttons
      const row = document.createElement("div")
      row.className = "flex flex-wrap gap-1 mt-1"

      buttons.filter(b => b.type === "QUICK_REPLY").forEach(b => {
        const pill = document.createElement("div")
        pill.className = "rounded-lg bg-white border border-gray-200 px-3 py-1.5 text-center shadow-sm"
        pill.style.flex = "1 1 auto"
        pill.style.minWidth = "0"
        pill.innerHTML = `<span class="text-[12px] font-medium" style="color: #00A5F4;">${this.escapeHtml(b.text || "Button")}</span>`
        row.appendChild(pill)
      })

      container.appendChild(row)
    } else {
      // CTA: stacked full-width buttons with icons
      buttons.forEach(b => {
        const btn = document.createElement("div")
        btn.className = "rounded-lg bg-white border border-gray-200 px-3 py-2 text-center shadow-sm mt-1 flex items-center justify-center gap-1.5"

        let icon = ""
        if (b.type === "URL") {
          icon = `<svg class="h-3.5 w-3.5" style="color: #00A5F4;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" /></svg>`
        } else if (b.type === "PHONE_NUMBER") {
          icon = `<svg class="h-3.5 w-3.5" style="color: #00A5F4;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 0 1-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 0 0-1.091-.852H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25z" /></svg>`
        } else if (b.type === "COPY_CODE") {
          icon = `<svg class="h-3.5 w-3.5" style="color: #00A5F4;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0 0 13.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 0 1-.75.75H9.75a.75.75 0 0 1-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 0 1-2.25 2.25H6.75A2.25 2.25 0 0 1 4.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 0 1 1.927-.184" /></svg>`
        }

        btn.innerHTML = `${icon}<span class="text-[12px] font-medium" style="color: #00A5F4;">${this.escapeHtml(b.text || "Button")}</span>`
        container.appendChild(btn)
      })
    }
  }

  updateCarouselPreview() {
    if (!this.hasPreviewCarouselCardsTarget) return

    // Read card data from DOM inputs directly
    let cardsData = []
    if (this.hasCardsContainerTarget) {
      const cards = this.cardsContainerTarget.querySelectorAll(".carousel-card")
      cardsData = Array.from(cards).map(card => {
        const cardData = {
          image_url: card.querySelector(".card-image-url")?.value || "",
          body: card.querySelector(".card-body")?.value || ""
        }

        // Read buttons from card-button-rows
        const btnRows = card.querySelectorAll(".card-button-row")
        if (btnRows.length > 0) {
          cardData.buttons = Array.from(btnRows).map(row => {
            const btn = {
              type: row.dataset.buttonType,
              text: row.querySelector(".card-btn-text")?.value || ""
            }
            if (row.dataset.buttonType === "URL") {
              btn.url = row.querySelector(".card-btn-url")?.value || ""
            }
            if (row.dataset.buttonType === "PHONE_NUMBER") {
              btn.phone_number = row.querySelector(".card-btn-phone")?.value || ""
            }
            return btn
          })
        }

        return cardData
      })
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

      // Build buttons HTML for card
      let buttonsHtml = ""
      const cardButtons = card.buttons || []
      if (cardButtons.length > 0) {
        buttonsHtml = cardButtons.map(b => {
          const icon = b.type === "URL"
            ? `<svg class="h-3 w-3 inline mr-1" style="color:#00A5F4;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" /></svg>`
            : ""
          return `<div style="border-top: 1px solid rgba(0,0,0,0.08);"><div class="py-2 text-center">${icon}<span class="text-[12px] font-medium" style="color: #00A5F4;">${this.escapeHtml(b.text || "Button")}</span></div></div>`
        }).join("")
      } else if (card.button_text) {
        // Legacy single button
        buttonsHtml = `<div style="border-top: 1px solid rgba(0,0,0,0.08);"><div class="py-2 text-center"><span class="text-[12px] font-medium" style="color: #00A5F4;">${this.escapeHtml(card.button_text)}</span></div></div>`
      }

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
        ${buttonsHtml}
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
