import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]
  
  connect() {
    console.log("Comparison controller connected!")
    
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
    console.log("Toggle location:", locationId)
    
    if (event.target.checked) {
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
      const locationIds = Array.from(this.selectedLocations).join(',')
      compareButton.href = `/locations/compare?location_ids=${locationIds}`
    } else {
      compareButton.classList.add('hidden')
    }
    
    console.log("Selected locations:", Array.from(this.selectedLocations))
  }
}