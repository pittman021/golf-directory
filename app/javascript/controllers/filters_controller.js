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

    // Initialize the hidden tags field with current tag values
    this.currentTags = new Set(this.getSelectedTags())
  }

  // Get currently selected tags from URL or DOM
  getSelectedTags() {
    // Try to get tags from URL params
    const url = new URL(window.location.href)
    const tagParams = url.searchParams.getAll('tags[]')
    
    if (tagParams.length > 0) {
      return tagParams
    }
    
    // If no tags in URL, try to get from existing tag elements
    const selectedTagElements = document.querySelectorAll('#selected_tags span')
    return Array.from(selectedTagElements).map(el => {
      const removeButton = el.querySelector('button')
      return removeButton ? removeButton.dataset.tag : null
    }).filter(tag => tag)
  }

  // Add a tag when a dropdown is changed
  addTag(event) {
    const dropdown = event.target
    const tagValue = dropdown.value
    
    if (!tagValue) return // Skip if nothing selected
    
    // Add the tag to our collection if it's not already there
    if (!this.currentTags.has(tagValue)) {
      this.currentTags.add(tagValue)
      
      // Update the hidden field with all current tags
      this.updateHiddenTagsField()
      
      // Update the visual display of selected tags
      this.updateSelectedTagsDisplay()
      
      // Reset the dropdown to placeholder state
      dropdown.value = ""
      
      // Submit the form with the updated tags
      this.submitForm()
    }
  }

  // Remove a tag when the × button is clicked
  removeTag(event) {
    const tagValue = event.currentTarget.dataset.tag
    
    if (tagValue && this.currentTags.has(tagValue)) {
      this.currentTags.delete(tagValue)
      
      // Update the hidden field with all current tags
      this.updateHiddenTagsField()
      
      // Update the visual display of selected tags
      this.updateSelectedTagsDisplay()
      
      // Submit the form with the updated tags
      this.submitForm()
    }
  }

  // Update the hidden field with all current tags
  updateHiddenTagsField() {
    const hiddenField = document.getElementById('hidden_tags_field')
    if (hiddenField) {
      // Clear existing tags
      const form = this.formTarget
      const existingTagInputs = form.querySelectorAll('input[name="tags[]"]')
      existingTagInputs.forEach(input => {
        if (input.id !== 'hidden_tags_field') {
          input.remove()
        }
      })
      
      // Add all tags as hidden inputs
      this.currentTags.forEach(tag => {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'tags[]'
        input.value = tag
        form.appendChild(input)
      })
    }
  }

  // Update the visual display of selected tags
  updateSelectedTagsDisplay() {
    const container = document.getElementById('selected_tags')
    if (!container) return
    
    // Clear existing tags
    container.innerHTML = ''
    
    // Add each tag as a span with remove button
    this.currentTags.forEach(tag => {
      const tagSpan = document.createElement('span')
      tagSpan.className = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-[#355E3B]/10 text-[#355E3B]'
      
      // Format the tag for display (replace underscores with spaces and capitalize)
      const displayTag = tag.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
      
      tagSpan.innerHTML = `
        ${displayTag}
        <button type="button" class="ml-1 text-[#355E3B] hover:text-[#355E3B]/80" data-tag="${tag}" data-action="click->filters#removeTag">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      `
      
      container.appendChild(tagSpan)
    })
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
      // Handle hidden tag fields
      else if (name === 'tags[]' && element.value) {
        url.searchParams.append(name, element.value)
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
      const comparisonController = document.querySelector('[data-controller*="comparison"]')?._stimulus
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