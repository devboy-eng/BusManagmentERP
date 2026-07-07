import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "urlInput", "preview", "filename", "uploadBtn"]

  pick() {
    this.fileInputTarget.click()
  }

  async upload() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    // Validate file type
    const allowed = ["image/jpeg", "image/png", "image/webp", "image/gif"]
    if (!allowed.includes(file.type)) {
      alert("Please select a valid image file (JPEG, PNG, WebP, or GIF)")
      return
    }

    // Validate file size (10MB max)
    if (file.size > 10 * 1024 * 1024) {
      alert("File is too large. Maximum size is 10MB.")
      return
    }

    // Show uploading state
    if (this.hasUploadBtnTarget) {
      this.uploadBtnTarget.disabled = true
      this.uploadBtnTarget.textContent = "Uploading..."
    }

    try {
      const formData = new FormData()
      formData.append("file", file)

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const response = await fetch("/uploads", {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken
        },
        body: formData
      })

      if (!response.ok) {
        const error = await response.json()
        throw new Error(error.error || "Upload failed")
      }

      const data = await response.json()

      // Fill the URL input
      if (this.hasUrlInputTarget) {
        this.urlInputTarget.value = data.url
        // Trigger input event for other Stimulus controllers
        this.urlInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      }

      // Show preview
      if (this.hasPreviewTarget) {
        this.previewTarget.innerHTML = `<img src="${data.url}" class="h-full w-full object-cover rounded">`
        this.previewTarget.classList.remove("hidden")
      }

      // Show filename
      if (this.hasFilenameTarget) {
        this.filenameTarget.textContent = data.filename
        this.filenameTarget.classList.remove("hidden")
      }
    } catch (error) {
      alert("Upload failed: " + error.message)
    } finally {
      if (this.hasUploadBtnTarget) {
        this.uploadBtnTarget.disabled = false
        this.uploadBtnTarget.textContent = "Upload"
      }
    }
  }
}
