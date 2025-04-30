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
        
        // Highlight the marker (using CSS for Advanced Markers or scale for legacy markers)
        if (marker.element) {
          marker.element.classList.add('highlighted-marker')
        } else {
          // Legacy marker - set a larger icon
          marker.setAnimation(google.maps.Animation.BOUNCE)
          setTimeout(() => {
            marker.setAnimation(null)
          }, 750)
        }
      }
    }
  }
  
  resetMarker(event) {
    if (!this.mapController || !this.mapController.map) return
    
    if (this.currentMarker) {
      // Remove highlight
      if (this.currentMarker.element) {
        this.currentMarker.element.classList.remove('highlighted-marker')
      } else {
        // Legacy marker - reset animation
        this.currentMarker.setAnimation(null)
      }
      
      this.currentMarker = null
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
      // Find the marker and info window
      const markerIndex = markers.findIndex(marker => marker.id.toString() === locationId.toString())
      if (markerIndex >= 0 && this.mapController.markers && this.mapController.infoWindows) {
        const marker = this.mapController.markers[markerIndex]
        const infoWindow = this.mapController.infoWindows[markerIndex]
        
        // Center the map on this marker
        this.mapController.map.setCenter({
          lat: parseFloat(markerData.latitude),
          lng: parseFloat(markerData.longitude)
        })
        this.mapController.map.setZoom(12)
        
        // Close all info windows first
        this.mapController.infoWindows.forEach(info => info.close())
        
        // Open this info window
        if (infoWindow && marker) {
          infoWindow.open(this.mapController.map, marker)
        }
        
        // Apply visual highlight to the card
        this.highlightCard(locationId)
      }
    }
  }
  
  highlightCard(locationId) {
    // Get all cards with this location ID
    const cards = document.querySelectorAll(`[data-location-id="${locationId}"]`)
    
    cards.forEach(card => {
      // Remove existing highlights from all cards
      document.querySelectorAll('.location-card, .location-row').forEach(element => {
        element.classList.remove('ring-2', 'ring-[#355E3B]', 'ring-offset-2', 'shadow-lg', 'z-10')
      })
      
      // Add highlight to this card
      card.classList.add('ring-2', 'ring-[#355E3B]', 'ring-offset-2', 'shadow-lg', 'z-10')
      card.style.transition = 'all 0.3s ease'
      
      // Scroll the card into view
      this.scrollToElement(card)
      
      // Remove highlight after some time
      setTimeout(() => {
        card.classList.remove('ring-2', 'ring-[#355E3B]', 'ring-offset-2', 'shadow-lg', 'z-10')
      }, 3000)
    })
  }
  
  scrollToElement(element) {
    // Find the scrollable container
    const container = document.querySelector('.lg\\:w-1\\/2.lg\\:overflow-y-auto')
    
    if (container && element) {
      // Scroll element into view
      container.scrollTo({
        top: element.offsetTop - 20,
        behavior: 'smooth'
      })
    }
  }
  
  getLocationId(element) {
    return element.dataset.locationId
  }
} 