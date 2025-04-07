import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    markers: Array,
    latitude: Number,
    longitude: Number,
    mapId: String
  }

  async connect() {
    console.log("Map controller connected");
    
    try {
      // Wait for Google Maps to be loaded
      await this.waitForGoogleMaps();
      
      const latitude = this.hasLatitudeValue ? parseFloat(this.latitudeValue) : 0;
      const longitude = this.hasLongitudeValue ? parseFloat(this.longitudeValue) : 0;
      const mapId = this.mapIdValue || window.GOOGLE_MAPS_CONFIG?.mapId;

      console.log("Initializing map with:", {
        latitude,
        longitude,
        mapId
      });

      // Create the map
      this.map = new google.maps.Map(this.element, {
        center: { lat: latitude, lng: longitude },
        zoom: 12,
        mapId: mapId,
        mapTypeControl: true,
        fullscreenControl: true,
        streetViewControl: true
      });

      // Create the marker
      const marker = new google.maps.marker.AdvancedMarkerElement({
        map: this.map,
        position: { lat: latitude, lng: longitude },
        title: "Location"
      });

    } catch (error) {
      console.error('Error initializing map:', error);
      console.error('Error details:', error.stack);
    }
  }

  waitForGoogleMaps() {
    return new Promise((resolve, reject) => {
      if (window.google && window.google.maps) {
        resolve();
      } else {
        const maxAttempts = 20;
        let attempts = 0;
        
        const interval = setInterval(() => {
          attempts++;
          if (window.google && window.google.maps) {
            clearInterval(interval);
            resolve();
          } else if (attempts >= maxAttempts) {
            clearInterval(interval);
            reject(new Error('Google Maps failed to load'));
          }
        }, 100);
      }
    });
  }

  addMarkers() {
    if (!this.hasMarkersValue) return;

    const bounds = new google.maps.LatLngBounds();
    
    this.markersValue.forEach(location => {
      const position = { 
        lat: parseFloat(location.latitude), 
        lng: parseFloat(location.longitude) 
      };
      
      const marker = new google.maps.marker.AdvancedMarkerElement({
        position: position,
        map: this.map,
        title: location.name
      });

      bounds.extend(position);

      const infoWindow = new google.maps.InfoWindow({
        content: `
          <div class="p-4 max-w-xs">
            <h3 class="text-lg font-bold mb-2">${location.name}</h3>
            <div class="space-y-1">
              <p><span class="font-medium">Courses:</span> ${location.courses_count}</p>
              ${location.average_rating ? 
                `<p><span class="font-medium">Rating:</span> ${location.average_rating}/5</p>` 
                : ''}
            </div>
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
    });

    if (this.markersValue.length > 1) {
      this.map.fitBounds(bounds);
    }
  }

  disconnect() {
    if (this.currentInfoWindow) {
      this.currentInfoWindow.close();
    }
  }
}