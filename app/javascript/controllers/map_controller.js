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
        // Ensure latitude and longitude are valid numbers
        const latitude = parseFloat(markerData.latitude);
        const longitude = parseFloat(markerData.longitude);
        
        // Skip invalid coordinates
        if (isNaN(latitude) || isNaN(longitude)) {
          console.warn(`Invalid coordinates for ${markerData.name}: [${markerData.latitude}, ${markerData.longitude}]`);
          return;
        }
        
        const position = { lat: latitude, lng: longitude };
        
        // Use Advanced Marker if available, fall back to regular Marker if not
        let marker;
        
        if (google.maps.marker && google.maps.marker.AdvancedMarkerElement) {
          // Use the new AdvancedMarkerElement
          marker = new google.maps.marker.AdvancedMarkerElement({
            map: this.map,
            position: position,
            title: markerData.name
          });
          
          // For advanced markers, we need to add click listeners differently
          if (markerData.info) {
            const infoWindow = new google.maps.InfoWindow({
              content: markerData.info
            });
            
            marker.addListener('click', () => {
              infoWindow.open(this.map, marker);
            });
          }
        } else {
          // Fall back to legacy Marker
          marker = new google.maps.Marker({
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
        }
        
        // Extend bounds to include this marker
        bounds.extend(position);
      });
      
      // Fit the map to show all markers if we have valid ones
      if (!bounds.isEmpty()) {
        if (markersData.length > 1) {
          this.map.fitBounds(bounds);
        } else if (markersData.length === 1) {
          // Get the valid marker data
          const validMarkers = markersData.filter(marker => {
            const lat = parseFloat(marker.latitude);
            const lng = parseFloat(marker.longitude);
            return !isNaN(lat) && !isNaN(lng);
          });
          
          if (validMarkers.length === 1) {
            this.map.setCenter({ 
              lat: parseFloat(validMarkers[0].latitude), 
              lng: parseFloat(validMarkers[0].longitude) 
            });
            this.map.setZoom(10);
          }
        }
      }
    } catch (error) {
      console.error("Error adding markers:", error);
    }
  }
}