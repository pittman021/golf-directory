import { Controller } from "@hotwired/stimulus"

// This controller handles direct uploads to Cloudinary
export default class extends Controller {
  static targets = ["input", "preview", "hiddenInput", "progressBar"]
  
  connect() {
    // Initialize Cloudinary widget if not already initialized
    if (typeof cloudinary === 'undefined') {
      console.error('Cloudinary widget not loaded')
      return
    }
  }
  
  // Open the Cloudinary upload widget
  openUploadWidget(event) {
    event.preventDefault()
    
    // Get cloudinary configuration from meta tags
    const cloudName = document.querySelector('meta[name="cloudinary-cloud-name"]')?.content
    const uploadPreset = document.querySelector('meta[name="cloudinary-upload-preset"]')?.content
    
    if (!cloudName || !uploadPreset) {
      alert('Cloudinary configuration is missing. Please check your environment variables.')
      return
    }
    
    // Open Cloudinary upload widget
    cloudinary.openUploadWidget({
      cloudName: cloudName,
      uploadPreset: uploadPreset,
      sources: ['local', 'url', 'camera'],
      showAdvancedOptions: false,
      cropping: true,
      multiple: false,
      defaultSource: 'local',
      styles: {
        palette: {
          window: "#FFFFFF",
          sourceBg: "#F4F4F5",
          windowBorder: "#90a0b3",
          tabIcon: "#355E3B",
          inactiveTabIcon: "#69778A",
          menuIcons: "#355E3B",
          link: "#355E3B",
          action: "#355E3B",
          inProgress: "#355E3B",
          complete: "#355E3B",
          error: "#c43737",
          textDark: "#000000",
          textLight: "#FFFFFF"
        }
      }
    }, (error, result) => {
      if (!error && result && result.event === "success") {
        // Set the Cloudinary URL to the input field
        const input = this.element.querySelector('.cloudinary-url-input')
        if (input) {
          input.value = result.info.secure_url
          // Trigger change event to update preview
          input.dispatchEvent(new Event('change'))
        }
      }
    })
  }
  
  // Update the preview when the URL changes
  updatePreview(event) {
    const url = event.target.value
    const previewDiv = this.element.querySelector('.cloudinary-preview')
    
    if (previewDiv) {
      if (url && url.trim() !== '') {
        previewDiv.innerHTML = `<img src="${url}" style="max-width: 200px; max-height: 150px; margin-top: 10px; border: 1px solid #ddd;">`
      } else {
        previewDiv.innerHTML = ''
      }
    }
  }
} 