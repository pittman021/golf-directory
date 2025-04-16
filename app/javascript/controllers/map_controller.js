import { Controller } from "@hotwired/stimulus"
import { MarkerClusterer } from "@googlemaps/markerclusterer"

export default class extends Controller {
  static targets = ["container", "markers"]
  
  connect() {
    if (typeof google === 'undefined') {
      // Add a listener to initialize map when Google Maps API is loaded
      document.addEventListener('google-maps-callback', this.initializeMap.bind(this))
    } else {
      this.initializeMap()
    }
  }
  
  initializeMap() {
    if (!this.hasContainerTarget) return
    
    try {
      // Get coordinates from data attribute or default to center of US
      const lat = parseFloat(this.containerTarget.dataset.lat) || 37.0902
      const lng = parseFloat(this.containerTarget.dataset.lng) || -95.7129
      const zoom = parseInt(this.containerTarget.dataset.zoom) || 4
      const mapType = this.containerTarget.dataset.mapType || 'standard'
      
      // Initialize the map
      this.map = new google.maps.Map(this.containerTarget, {
        center: { lat, lng },
        zoom: zoom,
        mapId: window.googleMapsConfig?.mapId,
        mapTypeControl: false,
        fullscreenControl: false,
        streetViewControl: false
      })
      
      // If we have markers, add them to the map
      if (this.hasMarkersTarget) {
        this.addMarkers()
      }
    } catch (error) {
      // Handle map initialization errors
    }
  }
  
  addMarkers() {
    const markersData = JSON.parse(this.markersTarget.dataset.markers)
    const markers = []
    
    markersData.forEach(markerData => {
      const marker = new google.maps.Marker({
        position: { lat: markerData.lat, lng: markerData.lng },
        map: this.map,
        title: markerData.title
      })
      
      // Add click event to marker
      marker.addListener('click', () => {
        window.location.href = markerData.url
      })
      
      markers.push(marker)
    })
    
    // Create a marker clusterer if we have multiple markers
    if (markers.length > 1) {
      new MarkerClusterer({ markers, map: this.map })
    }
    
    // If we have exactly one marker, center on it
    if (markers.length === 1) {
      this.map.setCenter(markers[0].getPosition())
      this.map.setZoom(10)
    }
  }
}