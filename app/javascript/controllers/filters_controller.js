// app/javascript/controllers/filters_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "table"]

  connect() {
    this.submitForm = this.debounce(this.submitForm.bind(this), 300)
  }

  filter() {
    this.submitForm()
  }

  submitForm() {
    const url = new URL(window.location.href)
    const formData = new FormData(this.formTarget)
    
    formData.forEach((value, key) => {
      if (value) {
        url.searchParams.set(key, value)
      } else {
        url.searchParams.delete(key)
      }
    })

    console.log("Fetching URL:", url.toString())

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`Network response was not ok: ${response.status}`)
      }
      return response.text()
    })
    .then(html => {
      console.log("Turbo Stream Response:", html)
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error("Error fetching Turbo Stream:", error)
    })
  }

  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
}