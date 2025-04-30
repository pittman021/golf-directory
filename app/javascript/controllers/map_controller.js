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
    
    // Set a timer to check if Google Maps API is loaded
    this.checkGoogleMapsLoaded();
  }
  
  checkGoogleMapsLoaded() {
    // Check if Google Maps is already loaded
    if (typeof google !== 'undefined' && google.maps) {
      this.initializeMap();
    } else {
      // Add a listener for when Google Maps API is loaded
      document.addEventListener('google-maps-callback', this.initializeMap.bind(this));
      
      // Fallback: retry after a short delay in case we missed the callback
      setTimeout(() => {
        if (typeof google !== 'undefined' && google.maps) {
          this.initializeMap();
        } else {
          console.log("Still waiting for Google Maps to load...");
          // Try again once more after a longer delay
          setTimeout(() => {
            if (typeof google !== 'undefined' && google.maps) {
              this.initializeMap();
            } else {
              console.error("Google Maps failed to load within the timeout period");
            }
          }, 3000);
        }
      }, 1000);
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
      
      // Apply info window style fixes
      this.applyInfoWindowFixes();
    } catch (error) {
      console.error("Error initializing map:", error);
    }
  }
  
  applyInfoWindowFixes() {
    // Apply CSS fixes for info windows
    const style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = `
      .gm-style .gm-style-iw-c {
        padding: 0 !important;
        overflow: visible !important;
        max-height: none !important;
      }
      .gm-style .gm-style-iw-d {
        overflow: visible !important;
        max-height: none !important;
      }
      .gm-style-iw-d::-webkit-scrollbar { 
        display: none;
      }
    `;
    document.head.appendChild(style);
    
    // Add event listener to catch any dynamically created info windows
    google.maps.event.addListener(this.map, 'idle', () => {
      // Force all info window containers to be visible
      const infoWindows = document.querySelectorAll('.gm-style-iw, .gm-style-iw-d');
      infoWindows.forEach(el => {
        el.style.overflow = 'visible';
        el.style.maxHeight = 'none';
      });
    });
  }
  
  addMarkers() {
    try {
      const markersData = this.markersValue;
      const bounds = new google.maps.LatLngBounds();
      
      console.log(`Adding ${markersData.length} markers`);
      
      // Store markers and info windows
      this.markers = [];
      this.infoWindows = [];
      
      markersData.forEach((markerData, index) => {
        // Ensure latitude and longitude are valid numbers
        const latitude = parseFloat(markerData.latitude);
        const longitude = parseFloat(markerData.longitude);
        
        // Skip invalid coordinates
        if (isNaN(latitude) || isNaN(longitude)) {
          console.warn(`Invalid coordinates for ${markerData.name}: [${markerData.latitude}, ${markerData.longitude}]`);
          return;
        }
        
        const position = { lat: latitude, lng: longitude };
        
        // Create enhanced info window content
        const infoContent = this.createInfoWindowContent(markerData);
        
        // Create info window with custom options
        const infoWindow = new google.maps.InfoWindow({
          content: infoContent,
          maxWidth: 320,
          pixelOffset: new google.maps.Size(0, -5),
          disableAutoPan: false,
          ariaLabel: markerData.name
        });
        
        this.infoWindows.push(infoWindow);
        
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
          marker.addListener('click', () => {
            // Close all info windows first
            this.infoWindows.forEach(info => info.close());
            
            // Open this info window - apply a slight delay to ensure DOM is ready
            setTimeout(() => {
              infoWindow.open(this.map, marker);
              // Fix any display issues with the info window
              document.querySelectorAll('.gm-style-iw, .gm-style-iw-d').forEach(el => {
                el.style.overflow = 'visible';
                el.style.maxHeight = 'none';
              });
            }, 10);
            
            // Trigger marker click event
            this.markerClicked(markerData.id);
          });
        } else {
          // Fall back to legacy Marker
          marker = new google.maps.Marker({
            position: position,
            map: this.map,
            title: markerData.name
          });
          
          // Add click listener
          marker.addListener('click', () => {
            // Close all info windows first
            this.infoWindows.forEach(info => info.close());
            
            // Open this info window - apply a slight delay to ensure DOM is ready
            setTimeout(() => {
              infoWindow.open(this.map, marker);
              // Fix any display issues with the info window
              document.querySelectorAll('.gm-style-iw, .gm-style-iw-d').forEach(el => {
                el.style.overflow = 'visible';
                el.style.maxHeight = 'none';
              });
            }, 10);
            
            // Trigger marker click event
            this.markerClicked(markerData.id);
          });
        }
        
        // Store the marker
        this.markers.push(marker);
        
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
  
  markerClicked(locationId) {
    // Find all location elements with this ID
    const locationElements = document.querySelectorAll(`[data-location-id="${locationId}"]`);
    
    // Trigger click event on the first matching element if found
    if (locationElements.length > 0) {
      const event = new Event('marker-clicked');
      locationElements[0].dispatchEvent(event);
      
      // Scroll the location into view
      const container = document.querySelector('.lg\\:w-1\\/2.lg\\:overflow-y-auto');
      if (container && locationElements[0]) {
        container.scrollTo({
          top: locationElements[0].offsetTop - 20,
          behavior: 'smooth'
        });
        
        // Add a more noticeable highlight
        locationElements.forEach(element => {
          // Remove highlight from all elements first
          element.classList.remove('ring-2', 'ring-[#355E3B]', 'ring-offset-2', 'shadow-lg');
          
          // Add highlight
          element.classList.add('ring-2', 'ring-[#355E3B]', 'ring-offset-2', 'shadow-lg');
          element.style.transition = 'all 0.3s ease';
          
          // Remove highlight after a delay
          setTimeout(() => {
            element.classList.remove('ring-2', 'ring-[#355E3B]', 'ring-offset-2', 'shadow-lg');
          }, 3000);
        });
      }
    }
  }
  
  createInfoWindowContent(markerData) {
    // Create a styled info window with image and details - with better compatibility for Google Maps
    return `
      <div style="width: 280px; padding: 0; margin: 0; overflow: visible; font-family: system-ui, -apple-system, sans-serif;">
        <div style="height: 140px; overflow: hidden;">
          <img src="${markerData.image_url}" alt="${markerData.name}" 
               style="width: 100%; height: 100%; object-fit: cover;">
        </div>
        <div style="padding: 12px; background-color: white;">
          <h3 style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #355E3B;">${markerData.name}</h3>
          <table style="width: 100%; border-collapse: collapse; font-size: 13px; color: #666;">
            <tr>
              <td style="padding-bottom: 4px;"><strong>Courses:</strong></td>
              <td style="padding-bottom: 4px;">${markerData.courses_count}</td>
            </tr>
            <tr>
              <td style="padding-bottom: 4px;"><strong>Avg Green Fee:</strong></td>
              <td style="padding-bottom: 4px;">${markerData.avg_green_fee}</td>
            </tr>
            <tr>
              <td style="padding-bottom: 4px;"><strong>Est. Trip Cost:</strong></td>
              <td style="padding-bottom: 4px;">${markerData.estimated_trip_cost}</td>
            </tr>
          </table>
          <div style="margin-top: 12px; text-align: right;">
            <a href="/locations/${markerData.id}" 
               style="display: inline-block; background-color: #355E3B; color: white; text-decoration: none; border: none; border-radius: 4px; padding: 6px 12px; font-size: 13px; cursor: pointer;">
              View Details
            </a>
          </div>
        </div>
      </div>
    `;
  }
}