// app/javascript/controllers/filters_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "regionSelect", "stateSelect"]

  connect() {
    console.log("Filters controller connected")
    this.submitForm = this.debounce(this.submitForm.bind(this), 300)
  }

  filter(event) {
    console.log("Filter method called", event.target.id)
    
    // If the region select changed, update the state options
    if (event.target.id === 'region') {
      const selectedRegion = event.target.value
      console.log("Selected region:", selectedRegion)
      
      // Fetch states for the selected region (or all states if "All Regions" is selected)
      fetch(`/locations/states_for_region?region=${encodeURIComponent(selectedRegion)}`, {
        headers: {
          "Accept": "application/json"
        }
      })
      .then(response => response.json())
      .then(states => {
        console.log("Received states:", states)
        // Clear current options
        this.stateSelectTarget.innerHTML = '<option value="">Select State</option>'
        
        // Add new options
        states.forEach(state => {
          const option = new Option(state, state)
          this.stateSelectTarget.add(option)
        })
      })
      .catch(error => {
        console.error("Error fetching states:", error)
      })
    }
    
    // Submit the form to update results
    this.submitForm()
  }

  submitForm() {
    console.log("SubmitForm method called")
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