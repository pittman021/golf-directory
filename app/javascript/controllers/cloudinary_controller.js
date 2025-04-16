import { Controller } from "@hotwired/stimulus"

// This controller handles direct uploads to Cloudinary
export default class extends Controller {
  static targets = ["input", "preview", "hiddenInput", "progressBar"]
  
  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('change', this.uploadFile.bind(this))
    }
  }
  
  // Upload the file directly to Cloudinary
  async uploadFile(event) {
    const file = event.target.files[0]
    if (!file) return
    
    // Show progress if we have a progress bar
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.classList.remove('hidden')
    }
    
    // Create form data
    const formData = new FormData()
    formData.append('file', file)
    formData.append('upload_preset', 'golf_directory') // Configure this to match your Cloudinary upload preset
    
    try {
      // Upload to Cloudinary
      const response = await fetch(
        `https://api.cloudinary.com/v1_1/${process.env.CLOUDINARY_CLOUD_NAME}/image/upload`,
        {
          method: 'POST',
          body: formData
        }
      )
      
      const data = await response.json()
      
      // If we have a hidden input, set the URL there
      if (this.hasHiddenInputTarget) {
        this.hiddenInputTarget.value = data.secure_url
      }
      
      // If we have a preview, update it
      if (this.hasPreviewTarget) {
        this.previewTarget.src = data.secure_url
        this.previewTarget.classList.remove('hidden')
      }
      
    } catch (error) {
      // Handle upload error
    } finally {
      // Hide progress if we have a progress bar
      if (this.hasProgressBarTarget) {
        this.progressBarTarget.classList.add('hidden')
      }
    }
  }
} 