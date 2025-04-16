import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]
  
  connect() {
    // Create shared state for selected locations or use existing one
    if (!window.selectedLocations) {
      window.selectedLocations = new Set()
      
      // Check if we have stored selections in sessionStorage
      const storedSelections = sessionStorage.getItem('selectedLocations')
      if (storedSelections) {
        storedSelections.split(',').forEach(id => {
          if (id) window.selectedLocations.add(id)
        })
      }
    }
    
    // Use the shared window state
    this.selectedLocations = window.selectedLocations
    
    // Set checkboxes based on stored selections
    this.checkboxTargets.forEach(checkbox => {
      const locationId = checkbox.dataset.locationId
      if (this.selectedLocations.has(locationId)) {
        checkbox.checked = true
      }
    })
    
    this.updateCompareButton()
  }
  
  toggleLocation(event) {
    const locationId = event.target.dataset.locationId
    
    if (event.target.checked) {
      // Clear existing selections if already have 2 selected
      if (this.selectedLocations.size >= 2) {
        event.target.checked = false
        alert("You can only compare two locations at a time")
        return
      }
      this.selectedLocations.add(locationId)
    } else {
      this.selectedLocations.delete(locationId)
    }
    
    // Store selections in sessionStorage
    sessionStorage.setItem('selectedLocations', Array.from(this.selectedLocations).join(','))
    
    // Update all other checkboxes with the same location ID
    document.querySelectorAll(`.location-compare-checkbox[data-location-id="${locationId}"]`).forEach(checkbox => {
      if (checkbox !== event.target) {
        checkbox.checked = event.target.checked
      }
    })
    
    this.updateCompareButton()
  }
  
  updateCompareButton() {
    const compareButton = document.getElementById('compare-button')
    if (!compareButton) return
    
    if (this.selectedLocations.size === 2) {
      compareButton.classList.remove('hidden')
      // Ensure we're using valid IDs by filtering out empty values
      const locationIds = Array.from(this.selectedLocations)
        .filter(id => id && id.trim() !== '')
        .join(',')
      
      // Only set href if we have valid IDs
      if (locationIds) {
        compareButton.href = `/locations/compare?location_ids=${locationIds}`
      } else {
        compareButton.classList.add('hidden')
      }
    } else {
      compareButton.classList.add('hidden')
    }
  }

  // Clear all selections (can be called from a reset button)
  clearSelections() {
    this.selectedLocations.clear()
    sessionStorage.removeItem('selectedLocations')
    
    // Uncheck all checkboxes
    document.querySelectorAll('.location-compare-checkbox').forEach(checkbox => {
      checkbox.checked = false
    })
    
    this.updateCompareButton()
  }
}