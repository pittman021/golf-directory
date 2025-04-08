import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    markers: Array,
    latitude: Number,
    longitude: Number
  }

  connect() {
    console.log("Map controller connected");
    this.initializeMapWhenReady();
  }

  initializeMapWhenReady() {
    if (window.google && window.google.maps) {
      this.initializeMap();
    } else {
      // Wait for Google Maps to be ready
      window.initMap = () => {
        this.initializeMap();
      };
    }
  }

  async initializeMap() {
    try {
      const lat = this.latitudeValue || 0;
      const lng = this.longitudeValue || 0;

      console.log("Initializing map with coordinates:", { lat, lng });

      const mapOptions = {
        center: { lat, lng },
        zoom: 13,
        mapTypeControl: true,
        fullscreenControl: true,
        streetViewControl: true
      };

      this.map = new google.maps.Map(this.element, mapOptions);
      
      if (this.hasMarkersValue) {
        await this.addMarkers();
      }

    } catch (error) {
      console.error("Error initializing map:", error);
    }
  }

  async addMarkers() {
    const bounds = new google.maps.LatLngBounds();
    
    this.markersValue.forEach(markerData => {
      const position = { 
        lat: parseFloat(markerData.latitude || 0), 
        lng: parseFloat(markerData.longitude || 0) 
      };
      
      if (position.lat && position.lng) {
        bounds.extend(position);

        const marker = new google.maps.Marker({
          map: this.map,
          position: position,
          title: markerData.name
        });

        const infoWindow = new google.maps.InfoWindow({
          content: `
            <div class="p-2">
              <h3 class="font-bold">${markerData.name}</h3>
              <p class="text-sm">${markerData.info || ''}</p>
            </div>
          `
        });

        marker.addListener('click', () => {
          if (this.currentInfoWindow) {
            this.currentInfoWindow.close();
          }
          infoWindow.open(this.map, marker);
          this.currentInfoWindow = infoWindow;
        });
      }
    });

    if (this.markersValue.length > 1) {
      this.map.fitBounds(bounds);
      this.map.setZoom(Math.min(this.map.getZoom(), 15));
    }
  }
}