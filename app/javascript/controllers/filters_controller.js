// app/javascript/controllers/filters_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "regionSelect", "stateSelect"]

  connect() {
    console.log("Filters controller connected")
    this.submitForm = this.debounce(this.submitForm.bind(this), 300)
    
    // If a region is already selected on page load, make sure states dropdown is populated
    const selectedRegion = this.regionSelectTarget.value
    if (selectedRegion) {
      console.log("Region already selected on page load:", selectedRegion)
      // Don't submit form since we're just initializing
      this.updateStatesForRegion(selectedRegion).catch(error => {
        console.error("Error initializing states dropdown:", error)
      })
    }
  }

  filter(event) {
    console.log("Filter method called", event.target.id)
    
    // If the region select changed, update the state options first, then submit
    if (event.target.id === 'region') {
      const selectedRegion = event.target.value
      console.log("Selected region:", selectedRegion)
      
      // Fetch states for the selected region (or all states if "All Regions" is selected)
      this.updateStatesForRegion(selectedRegion)
        .then(() => this.submitForm())
        .catch(error => {
          console.error("Error updating states:", error)
          this.submitForm() // Still submit the form even if states update fails
        })
    } else {
      // For other filters, just submit the form
      this.submitForm()
    }
  }
  
  async updateStatesForRegion(selectedRegion) {
    try {
      // Determine which endpoint to use based on the current path
      const endpoint = window.location.pathname === '/' || window.location.pathname === '/pages/home'
        ? '/pages/states_for_region'
        : '/locations/states_for_region';
      
      const response = await fetch(`${endpoint}?region=${encodeURIComponent(selectedRegion)}`, {
        headers: {
          "Accept": "application/json"
        }
      })
      
      if (!response.ok) {
        throw new Error(`Network response was not ok: ${response.status}`)
      }
      
      const states = await response.json()
      console.log("Received states:", states)
      
      // Clear current options
      this.stateSelectTarget.innerHTML = '<option value="">Select State</option>'
      
      // Add new options
      states.forEach(state => {
        const option = new Option(state, state)
        this.stateSelectTarget.add(option)
      })
      
      return states
    } catch (error) {
      console.error("Error in updateStatesForRegion:", error)
      throw error
    }
  }

  submitForm() {
    console.log("SubmitForm method called")
    const url = new URL(window.location.href)
    
    // Clear existing params except those we want to preserve
    for (const key of [...url.searchParams.keys()]) {
      if (!['utf8', 'authenticity_token'].includes(key)) {
        url.searchParams.delete(key)
      }
    }
    
    // Use FormData to gather all inputs, including multi-selects
    const form = this.formTarget
    const formElements = form.elements
    
    for (let i = 0; i < formElements.length; i++) {
      const element = formElements[i]
      const name = element.name
      
      // Skip buttons and elements without names
      if (!name || element.type === 'submit') continue
      
      // Handle select multiple
      if (element.type === 'select-multiple') {
        const selectedOptions = Array.from(element.selectedOptions)
        if (selectedOptions.length > 0) {
          selectedOptions.forEach(option => {
            url.searchParams.append(name, option.value)
          })
        }
      } 
      // Handle regular inputs
      else if (element.value) {
        url.searchParams.set(name, element.value)
      }
    }

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
      console.log("Turbo Stream Response received")
      Turbo.renderStreamMessage(html)
      
      // Refresh comparison checkboxes after filter
      const comparisonController = document.querySelector('[data-controller*="comparison"]')._stimulus
      if (comparisonController) {
        // This will ensure checkboxes are properly checked
        setTimeout(() => {
          comparisonController.connect()
        }, 100)
      }
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