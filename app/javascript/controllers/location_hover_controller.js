import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Location hover controller connected")
    this.mapController = this.application.getControllerForElementAndIdentifier(
      document.getElementById("locations-map"),
      "map"
    )
  }

  highlightMarker(event) {
    if (!this.mapController || !this.mapController.map) return
    
    const locationId = this.getLocationId(event.currentTarget)
    if (!locationId) return
    
    // Find the marker for this location
    const markers = this.mapController.markersValue
    const markerIndex = markers.findIndex(marker => marker.id.toString() === locationId.toString())
    
    if (markerIndex >= 0 && this.mapController.markers) {
      const marker = this.mapController.markers[markerIndex]
      if (marker) {
        // Store current marker for reset
        this.currentMarker = marker
        
        // Highlight the marker
        marker.element?.classList.add('highlighted-marker')
        
        // Open info window for this marker
        if (this.mapController.infoWindows && this.mapController.infoWindows[markerIndex]) {
          this.mapController.infoWindows[markerIndex].open(this.mapController.map, marker)
        }
      }
    }
  }
  
  resetMarker(event) {
    if (!this.mapController || !this.mapController.map) return
    
    if (this.currentMarker) {
      // Remove highlight
      this.currentMarker.element?.classList.remove('highlighted-marker')
      
      // Close all info windows
      if (this.mapController.infoWindows) {
        this.mapController.infoWindows.forEach(infoWindow => {
          infoWindow.close()
        })
      }
    }
  }
  
  focusMarker(event) {
    if (!this.mapController || !this.mapController.map) return
    
    const locationId = this.getLocationId(event.currentTarget)
    if (!locationId) return
    
    // Find the marker data for this location
    const markers = this.mapController.markersValue
    const markerData = markers.find(marker => marker.id.toString() === locationId.toString())
    
    if (markerData) {
      // Center the map on this marker
      this.mapController.map.setCenter({
        lat: parseFloat(markerData.latitude),
        lng: parseFloat(markerData.longitude)
      })
      this.mapController.map.setZoom(10)
      
      // Highlight and show info for this marker
      this.highlightMarker(event)
      
      // Scroll the clicked location into view if needed
      this.scrollToLocation(locationId)
    }
  }
  
  scrollToLocation(locationId) {
    // Get the right container - now the parent 1/2 width column is scrollable
    const container = document.querySelector('.lg\\:w-1\\/2.lg\\:overflow-y-auto')
    const element = document.querySelector(`[data-location-id="${locationId}"]`)
    
    if (container && element) {
      // Calculate position - need to account for container's own offset
      const containerRect = container.getBoundingClientRect()
      const elementRect = element.getBoundingClientRect()
      
      // Scroll the container
      container.scrollTo({
        top: element.offsetTop - 20,
        behavior: 'smooth'
      })
      
      // Add a temporary highlight
      element.classList.add('bg-[#355E3B]/10')
      setTimeout(() => {
        element.classList.remove('bg-[#355E3B]/10')
      }, 2000)
    }
  }
  
  getLocationId(element) {
    return element.dataset.locationId
  }
} 