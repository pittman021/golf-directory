// app/javascript/controllers/filters_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "regionSelect", "stateSelect"]

  connect() {
    this.submitForm = this.debounce(this.submitForm.bind(this), 300)
    
    // Initialize the hidden tags field with current tag values
    this.currentTags = new Set(this.getSelectedTags())
  }

  // Get currently selected tags from URL or DOM
  getSelectedTags() {
    const url = new URL(window.location.href)
    return url.searchParams.getAll('tags[]')
  }
  

  // Add a tag when a dropdown is changed
  addTag(event) {
    const dropdown = event.target
    const tagValue = dropdown.value

    console.log(tagValue)
    
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
  const form = this.formTarget

  // Remove any previously added tag fields (not the base hidden field if present)
  const existingTagInputs = form.querySelectorAll('input[name="tags[]"]')
  existingTagInputs.forEach(input => input.remove())

  // Add one hidden field for each tag
  this.currentTags.forEach(tag => {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = 'tags[]'
    input.value = tag
    form.appendChild(input)
  })
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
      
      // Format the tag for display with namespace handling
      let displayTag
      if (tag.startsWith('golf:')) {
        displayTag = 'Golf: ' + tag.replace('golf:', '').replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
      } else if (tag.startsWith('style:')) {
        displayTag = 'Style: ' + tag.replace('style:', '').replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
      } else {
        // Default formatting for non-namespaced tags
        displayTag = tag.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
      }
      
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
   
      this.submitForm()
  }
  
  

  submitForm() {
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
        console.log('searchparams', url);
      }
    }

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
      // Process Turbo Stream response
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const turboStreamElements = doc.querySelectorAll('turbo-stream')
      
      // Process each turbo-stream element
      turboStreamElements.forEach(el => {
        const action = el.getAttribute('action')
        const target = el.getAttribute('target')
        const template = el.querySelector('template')
        
        if (template && target) {
          const targetElement = document.getElementById(target)
          if (targetElement) {
            if (action === 'replace') {
              targetElement.innerHTML = template.content.firstElementChild.innerHTML
            } else if (action === 'update') {
              targetElement.innerHTML = template.innerHTML
            }
          }
        }
      })
      
      // Update URL in browser without full page reload
      window.history.pushState({}, '', url)
    })
    .catch(() => {
      // Error handling for fetch operation
    })
  }
  
  // Utility function to prevent rapid multiple submits
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