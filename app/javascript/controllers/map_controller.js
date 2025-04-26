import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "markers"]
  static values = {
    latitude: Number,
    longitude: Number,
    markers: Array
  }
  
  connect() {
    console.log("Map controller connected");
    if (typeof google === 'undefined') {
      // Add a listener to initialize map when Google Maps API is loaded
      document.addEventListener('google-maps-callback', this.initializeMap.bind(this))
    } else {
      this.initializeMap()
    }
  }
  
  initializeMap() {
    try {
      console.log("Initializing map...");
      
      // Get coordinates from values
      const lat = this.latitudeValue || 37.0902;
      const lng = this.longitudeValue || -95.7129;
      const zoom = 8;
      
      console.log(`Map center: ${lat}, ${lng}`);
      
      // Initialize the map on the element with the controller
      this.element.style.height = '400px';
      this.map = new google.maps.Map(this.element, {
        center: { lat, lng },
        zoom: zoom,
        mapId: window.googleMapsConfig?.mapId,
        mapTypeControl: false,
        fullscreenControl: false,
        streetViewControl: false
      });
      
      this.element.style.backgroundColor = "#e5e5e5";
      
      // If we have markers data, add them to the map
      if (this.hasMarkersValue) {
        this.addMarkers();
      }
    } catch (error) {
      console.error("Error initializing map:", error);
    }
  }
  
  addMarkers() {
    try {
      const markersData = this.markersValue;
      const bounds = new google.maps.LatLngBounds();
      
      console.log(`Adding ${markersData.length} markers`);
      
      markersData.forEach(markerData => {
        const position = { 
          lat: markerData.latitude || 0, 
          lng: markerData.longitude || 0 
        };
        
        const marker = new google.maps.Marker({
          position: position,
          map: this.map,
          title: markerData.name
        });
        
        // Add info window if we have info
        if (markerData.info) {
          const infoWindow = new google.maps.InfoWindow({
            content: markerData.info
          });
          
          marker.addListener('click', () => {
            infoWindow.open(this.map, marker);
          });
        }
        
        // Extend bounds to include this marker
        bounds.extend(position);
      });
      
      // Fit the map to show all markers
      if (markersData.length > 1) {
        this.map.fitBounds(bounds);
      } else if (markersData.length === 1) {
        this.map.setCenter({ 
          lat: markersData[0].latitude, 
          lng: markersData[0].longitude 
        });
        this.map.setZoom(10);
      }
    } catch (error) {
      console.error("Error adding markers:", error);
    }
  }
}