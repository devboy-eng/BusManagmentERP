import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "tab", "tabPanel",
    "leadSearch", "leadsList", "leadCheckbox", "recipientCount",
    "csvFile", "csvPreview", "csvTableBody",
    "templateSelect", "variablesSection", "variableInputs",
    "previewEmpty", "previewBubble", "previewMedia", "previewMediaLabel",
    "previewHeader", "previewBody", "previewFooter", "previewButtons"
  ]

  connect() {
    this.csvContacts = []
    if (this.hasRecipientCountTarget) {
      this.updateRecipientCount()
    }
  }

  // ---- Tab Switching ----
  switchTab(event) {
    const targetTab = event.currentTarget.dataset.tab

    this.tabTargets.forEach(tab => {
      if (tab.dataset.tab === targetTab) {
        tab.classList.remove("border-transparent", "text-gray-500")
        tab.classList.add("border-indigo-600", "text-indigo-600")
      } else {
        tab.classList.remove("border-indigo-600", "text-indigo-600")
        tab.classList.add("border-transparent", "text-gray-500")
      }
    })

    this.tabPanelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tab !== targetTab)
    })
  }

  // ---- Lead Filtering ----
  filterLeads() {
    const query = this.leadSearchTarget.value.toLowerCase()
    const items = this.leadsListTarget.querySelectorAll(".lead-item")

    items.forEach(item => {
      const name = item.dataset.name || ""
      const phone = item.dataset.phone || ""
      const match = name.includes(query) || phone.includes(query)
      item.classList.toggle("hidden", !match)
    })
  }

  selectAllLeads() {
    this.leadCheckboxTargets.forEach(cb => {
      const item = cb.closest(".lead-item")
      if (!item.classList.contains("hidden")) {
        cb.checked = true
      }
    })
    this.updateRecipientCount()
  }

  deselectAllLeads() {
    this.leadCheckboxTargets.forEach(cb => { cb.checked = false })
    this.updateRecipientCount()
  }

  updateRecipientCount() {
    const leadCount = this.hasLeadCheckboxTarget ? this.leadCheckboxTargets.filter(cb => cb.checked).length : 0
    const csvCount = (this.csvContacts || []).length
    const total = leadCount + csvCount
    if (this.hasRecipientCountTarget) {
      this.recipientCountTarget.textContent = `${total} selected`
    }
  }

  // ---- CSV Parsing ----
  parseCSV(event) {
    const file = event.currentTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      const text = e.target.result
      const lines = text.split(/\r?\n/).filter(l => l.trim().length > 0)
      if (lines.length < 2) return

      // Parse header
      const headers = lines[0].split(",").map(h => h.trim().toLowerCase().replace(/['"]/g, ""))
      const nameIdx = headers.indexOf("name")
      const phoneIdx = headers.indexOf("phone")

      if (phoneIdx === -1) {
        alert('CSV must have a "phone" column')
        return
      }

      this.csvContacts = []
      this.csvTableBodyTarget.innerHTML = ""

      for (let i = 1; i < lines.length; i++) {
        const cols = this.parseCSVLine(lines[i])
        const name = nameIdx >= 0 ? (cols[nameIdx] || "").trim() : ""
        const phone = (cols[phoneIdx] || "").trim()
        if (!phone) continue

        this.csvContacts.push({ name, phone })
        const idx = this.csvContacts.length - 1

        const tr = document.createElement("tr")
        tr.classList.add("hover:bg-gray-50")
        tr.dataset.csvIndex = idx
        tr.innerHTML = `
          <td class="px-3 py-2 text-xs text-gray-900">${this.escapeHtml(name)}</td>
          <td class="px-3 py-2 text-xs text-gray-500">${this.escapeHtml(phone)}</td>
          <td class="px-3 py-2 text-right">
            <button type="button" class="text-[11px] text-red-500 hover:text-red-700" data-action="click->follow-up-form#removeCSVContact" data-index="${idx}">Remove</button>
          </td>
        `
        this.csvTableBodyTarget.appendChild(tr)
      }

      this.renderCSVHiddenInputs()
      this.csvPreviewTarget.classList.remove("hidden")
      this.updateRecipientCount()
    }
    reader.readAsText(file)
  }

  parseCSVLine(line) {
    const result = []
    let current = ""
    let inQuotes = false

    for (let i = 0; i < line.length; i++) {
      const ch = line[i]
      if (inQuotes) {
        if (ch === '"') {
          if (i + 1 < line.length && line[i + 1] === '"') {
            current += '"'
            i++
          } else {
            inQuotes = false
          }
        } else {
          current += ch
        }
      } else {
        if (ch === '"') {
          inQuotes = true
        } else if (ch === ',') {
          result.push(current)
          current = ""
        } else {
          current += ch
        }
      }
    }
    result.push(current)
    return result
  }

  removeCSVContact(event) {
    const idx = parseInt(event.currentTarget.dataset.index)
    this.csvContacts.splice(idx, 1)
    this.rebuildCSVTable()
    this.renderCSVHiddenInputs()
    this.updateRecipientCount()

    if (this.csvContacts.length === 0) {
      this.csvPreviewTarget.classList.add("hidden")
    }
  }

  rebuildCSVTable() {
    this.csvTableBodyTarget.innerHTML = ""
    this.csvContacts.forEach((c, idx) => {
      const tr = document.createElement("tr")
      tr.classList.add("hover:bg-gray-50")
      tr.dataset.csvIndex = idx
      tr.innerHTML = `
        <td class="px-3 py-2 text-xs text-gray-900">${this.escapeHtml(c.name)}</td>
        <td class="px-3 py-2 text-xs text-gray-500">${this.escapeHtml(c.phone)}</td>
        <td class="px-3 py-2 text-right">
          <button type="button" class="text-[11px] text-red-500 hover:text-red-700" data-action="click->follow-up-form#removeCSVContact" data-index="${idx}">Remove</button>
        </td>
      `
      this.csvTableBodyTarget.appendChild(tr)
    })
  }

  renderCSVHiddenInputs() {
    // Remove existing hidden inputs
    this.element.querySelectorAll(".csv-hidden-input").forEach(el => el.remove())

    this.csvContacts.forEach((c, idx) => {
      const nameInput = document.createElement("input")
      nameInput.type = "hidden"
      nameInput.name = `csv_contacts[][name]`
      nameInput.value = c.name
      nameInput.classList.add("csv-hidden-input")
      this.element.appendChild(nameInput)

      const phoneInput = document.createElement("input")
      phoneInput.type = "hidden"
      phoneInput.name = `csv_contacts[][phone]`
      phoneInput.value = c.phone
      phoneInput.classList.add("csv-hidden-input")
      this.element.appendChild(phoneInput)
    })
  }

  // ---- Template Preview ----
  selectTemplate() {
    const select = this.templateSelectTarget
    const option = select.options[select.selectedIndex]

    if (!option || !option.value) {
      this.previewEmptyTarget.classList.remove("hidden")
      this.previewBubbleTarget.classList.add("hidden")
      this.variablesSectionTarget.classList.add("hidden")
      return
    }

    const body = option.dataset.body
    const headerType = option.dataset.headerType
    const headerText = option.dataset.headerText
    const footer = option.dataset.footer
    const category = option.dataset.category
    const varCount = parseInt(option.dataset.vars) || 0
    let buttons = []
    try { buttons = JSON.parse(option.dataset.buttons) } catch(e) {}

    // Show bubble, hide empty
    this.previewEmptyTarget.classList.add("hidden")
    this.previewBubbleTarget.classList.remove("hidden")

    // Media header
    if (["image", "video", "document"].includes(headerType)) {
      this.previewMediaTarget.classList.remove("hidden")
      this.previewMediaLabelTarget.textContent = headerType.charAt(0).toUpperCase() + headerType.slice(1)
    } else {
      this.previewMediaTarget.classList.add("hidden")
    }

    // Header text
    if (headerType === "text" && headerText) {
      this.previewHeaderTarget.textContent = headerText
      this.previewHeaderTarget.classList.remove("hidden")
    } else {
      this.previewHeaderTarget.classList.add("hidden")
    }

    // Body
    this.previewBodyTarget.textContent = category === "authentication"
      ? "(Meta auto-generates the OTP message body)"
      : body

    // Footer
    if (footer) {
      this.previewFooterTarget.textContent = footer
      this.previewFooterTarget.classList.remove("hidden")
    } else {
      this.previewFooterTarget.classList.add("hidden")
    }

    // Buttons
    this.renderPreviewButtons(buttons)

    // Variable inputs
    this.variableInputsTarget.innerHTML = ""
    if (varCount > 0) {
      for (let i = 0; i < varCount; i++) {
        const div = document.createElement("div")
        if (category === "authentication") {
          div.innerHTML = `
            <label class="block text-[11px] text-gray-600 mb-0.5">OTP Code</label>
            <input type="text" name="variables[]" placeholder="Enter the OTP code (e.g. 123456)"
                   data-action="input->follow-up-form#updatePreviewVariables"
                   class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs text-gray-900 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none">`
        } else {
          div.innerHTML = `
            <label class="block text-[11px] text-gray-600 mb-0.5">Variable {{${i + 1}}}</label>
            <input type="text" name="variables[]" placeholder="Enter value for {{${i + 1}}}"
                   data-action="input->follow-up-form#updatePreviewVariables"
                   class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-xs text-gray-900 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:outline-none">`
        }
        this.variableInputsTarget.appendChild(div)
      }
      this.variablesSectionTarget.classList.remove("hidden")
    } else {
      this.variablesSectionTarget.classList.add("hidden")
    }
  }

  updatePreviewVariables() {
    const select = this.templateSelectTarget
    const option = select.options[select.selectedIndex]
    if (!option || !option.value) return

    const category = option.dataset.category
    if (category === "authentication") return

    let body = option.dataset.body
    const inputs = this.variableInputsTarget.querySelectorAll("input[name='variables[]']")

    inputs.forEach((input, i) => {
      const val = input.value || `{{${i + 1}}}`
      body = body.replace(`{{${i + 1}}}`, val)
    })

    this.previewBodyTarget.textContent = body
  }

  renderPreviewButtons(buttons) {
    const container = this.previewButtonsTarget
    container.innerHTML = ""

    if (!buttons || buttons.length === 0) {
      container.classList.add("hidden")
      return
    }

    container.classList.remove("hidden")
    const hasQR = buttons.some(b => b.type === "QUICK_REPLY")

    if (hasQR) {
      const wrap = document.createElement("div")
      wrap.className = "flex flex-wrap gap-1 mt-1"
      buttons.filter(b => b.type === "QUICK_REPLY").forEach(b => {
        const div = document.createElement("div")
        div.className = "rounded-lg bg-white border border-gray-200 px-2.5 py-1 text-center shadow-sm"
        div.style.flex = "1 1 auto"
        div.style.minWidth = "0"
        div.innerHTML = `<span class="text-[11px] font-medium" style="color: #00A5F4;">${this.escapeHtml(b.text)}</span>`
        wrap.appendChild(div)
      })
      container.appendChild(wrap)
    } else {
      buttons.forEach(b => {
        const div = document.createElement("div")
        div.className = "rounded-lg bg-white border border-gray-200 px-2.5 py-1.5 text-center shadow-sm mt-1 flex items-center justify-center gap-1"
        let icon = ""
        if (b.type === "URL") {
          icon = '<svg class="h-3 w-3" style="color: #00A5F4;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" /></svg>'
        } else if (b.type === "PHONE_NUMBER") {
          icon = '<svg class="h-3 w-3" style="color: #00A5F4;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 0 1-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 0 0-1.091-.852H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25z" /></svg>'
        } else if (b.type === "COPY_CODE") {
          icon = '<svg class="h-3 w-3" style="color: #00A5F4;" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0 0 13.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 0 1-.75.75H9.75a.75.75 0 0 1-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 0 1-2.25 2.25H6.75A2.25 2.25 0 0 1 4.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 0 1 1.927-.184" /></svg>'
        }
        div.innerHTML = `${icon}<span class="text-[11px] font-medium" style="color: #00A5F4;">${this.escapeHtml(b.text)}</span>`
        container.appendChild(div)
      })
    }
  }

  // ---- Helpers ----
  escapeHtml(str) {
    const div = document.createElement("div")
    div.appendChild(document.createTextNode(str || ""))
    return div.innerHTML
  }
}
