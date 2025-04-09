import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]
  
  connect() {
    console.log("Comparison controller connected!")
    this.selectedLocations = new Set()
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