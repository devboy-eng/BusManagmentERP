import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "headerTypeSelect",
    "headerTextField",
    "headerMediaField",
    "previewHeader",
    "previewBody",
    "previewFooter",
    "previewMediaPlaceholder",
    "bodyInput",
    "footerInput",
    "headerTextInput",
    "headerMediaInput"
  ]

  connect() {
    this.updatePreview()
    this.headerTypeChanged()
  }

  headerTypeChanged() {
    const type = this.headerTypeSelectTarget.value

    // Show/hide conditional fields
    if (this.hasHeaderTextFieldTarget) {
      this.headerTextFieldTarget.classList.toggle("hidden", type !== "text")
    }
    if (this.hasHeaderMediaFieldTarget) {
      this.headerMediaFieldTarget.classList.toggle("hidden", !["image", "video", "document"].includes(type))
    }

    this.updatePreview()
  }

  updatePreview() {
    const headerType = this.hasHeaderTypeSelectTarget ? this.headerTypeSelectTarget.value : "none"

    // Update header preview
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

    // Update media placeholder
    if (this.hasPreviewMediaPlaceholderTarget) {
      if (["image", "video", "document"].includes(headerType)) {
        const icons = { image: "🖼️ Image", video: "🎥 Video", document: "📄 Document" }
        this.previewMediaPlaceholderTarget.textContent = icons[headerType] || ""
        this.previewMediaPlaceholderTarget.classList.remove("hidden")
      } else {
        this.previewMediaPlaceholderTarget.classList.add("hidden")
      }
    }

    // Update body preview
    if (this.hasPreviewBodyTarget && this.hasBodyInputTarget) {
      this.previewBodyTarget.textContent = this.bodyInputTarget.value || "Message body will appear here..."
    }

    // Update footer preview
    if (this.hasPreviewFooterTarget && this.hasFooterInputTarget) {
      const footerText = this.footerInputTarget.value
      this.previewFooterTarget.textContent = footerText
      this.previewFooterTarget.classList.toggle("hidden", !footerText)
    }
  }
}
