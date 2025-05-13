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
        /* overflow: visible !important; */ /* Let Google Maps handle this initially */
        max-height: none !important;
        box-shadow: 0 2px 7px 1px rgba(0,0,0,0.3);
        border-radius: 8px !important;
      }
      .gm-style .gm-style-iw-d {
        /* overflow: visible !important; */ /* Let Google Maps handle this initially */
        max-height: none !important;
      }
      .gm-style-iw-d::-webkit-scrollbar { 
        display: none;
      }
      .gm-ui-hover-effect {
        display: none !important;
      }
      .gm-style-iw-tc, .gm-style-iw-tc:after {
        display: none !important;
      }
    `;
    document.head.appendChild(style);
    
    // Add event listener to catch any dynamically created info windows
    google.maps.event.addListener(this.map, 'idle', () => {
      // Force all info window containers to be visible
      const infoWindows = document.querySelectorAll('.gm-style-iw, .gm-style-iw-d');
      infoWindows.forEach(el => {
        /* el.style.overflow = 'visible'; // Controlled by panning logic now */
        el.style.maxHeight = 'none';
      });
    });
    
    // Remove listener that disables auto pan
    // google.maps.event.addListener(this.map, 'click', () => {
    //   // Make sure the map doesn't recenter on info window open
    //   if (this.map) {
    //     this.map.setOptions({ disableAutoPan: true });
    //   }
    // });
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

        console.log(latitude, longitude);
        
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
          disableAutoPan: true, // Ensure this is active
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
            // Save current map center and zoom
            // const currentCenter = this.map.getCenter(); // Not needed, we pan to new state
            // const currentZoom = this.map.getZoom(); // Not needed
            
            // Close all info windows first
            this.infoWindows.forEach(info => info.close());
            
            // Open this info window
            infoWindow.open(this.map, marker);

            // Listen for the DOM ready event
            google.maps.event.addListenerOnce(infoWindow, 'domready', () => {
              // First, pan the map to the marker
              if (marker && typeof marker.getPosition === 'function') {
                const pos = marker.getPosition();
                if (pos && !isNaN(pos.lat()) && !isNaN(pos.lng())) {
                  this.map.panTo(pos);
                } else {
                  console.warn("Invalid marker position for AdvancedMarkerElement", pos, markerData);
                }
              }
              
              // Then, after a short delay for panTo to settle, adjust for InfoWindow visibility
              setTimeout(() => {
                this.panMapToShowInfoWindow(infoWindow);
              }, 100); // Slightly increased delay for panTo animation
            });
            
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
            // Save current map center and zoom
            // const currentCenter = this.map.getCenter(); // Not needed
            // const currentZoom = this.map.getZoom(); // Not needed
            
            // Close all info windows first
            this.infoWindows.forEach(info => info.close());
            
            // Open this info window
            infoWindow.open(this.map, marker);

            // Listen for the DOM ready event
            google.maps.event.addListenerOnce(infoWindow, 'domready', () => {
              // First, pan the map to the marker
              if (marker && typeof marker.getPosition === 'function') {
                const pos = marker.getPosition();
                if (pos && !isNaN(pos.lat()) && !isNaN(pos.lng())) {
                  this.map.panTo(pos);
                } else {
                  console.warn("Invalid marker position for legacy Marker", pos, markerData);
                }
              }
              
              // Then, after a short delay for panTo to settle, adjust for InfoWindow visibility
              setTimeout(() => {
                this.panMapToShowInfoWindow(infoWindow);
              }, 100); // Slightly increased delay for panTo animation
            });
            
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
    if (markerData.type === 'course') {
      // Create a styled info window for courses
      return `
        <div style="width: 280px; padding: 0; margin: 0; /* overflow: visible; */ font-family: system-ui, -apple-system, sans-serif; cursor: pointer;" 
             onclick="window.location.href='/courses/${markerData.id}'">
          <div style="height: 140px; overflow: hidden; position: relative;">
            <img src="${markerData.image_url}" alt="${markerData.name}" 
                 style="width: 100%; height: 100%; object-fit: cover;">
            <div style="position: absolute; top: 8px; right: 8px;">
              <span style="display: inline-block; background-color: rgba(255,255,255,0.8); border-radius: 50%; width: 24px; height: 24px; text-align: center; line-height: 24px; font-weight: bold; cursor: pointer;"
                    onclick="event.stopPropagation(); this.closest('.gm-style-iw-a').querySelector('.gm-ui-hover-effect').click();">×</span>
            </div>
            <div style="position: absolute; bottom: 0; right: 0; background-color: rgba(0,0,0,0.7); color: white; padding: 6px 10px;">
              <span style="font-size: 14px; font-weight: 600;">${markerData.name}</span>
            </div>
          </div>
          <div style="padding: 12px; background-color: white;">
            <table style="width: 100%; border-collapse: collapse; font-size: 13px; color: #666;">
              <tr>
                <td style="padding-bottom: 4px;"><strong>Type:</strong></td>
                <td style="padding-bottom: 4px;">${markerData.course_type}</td>
              </tr>
              <tr>
                <td style="padding-bottom: 4px;"><strong>Green Fee:</strong></td>
                <td style="padding-bottom: 4px;">${markerData.green_fee}</td>
              </tr>
              <tr>
                <td style="padding-bottom: 4px;"><strong>Holes:</strong></td>
                <td style="padding-bottom: 4px;">${markerData.number_of_holes}</td>
              </tr>
              <tr>
                <td style="padding-bottom: 4px;"><strong>Par:</strong></td>
                <td style="padding-bottom: 4px;">${markerData.par}</td>
              </tr>
              <tr>
                <td style="padding-bottom: 4px;"><strong>Yardage:</strong></td>
                <td style="padding-bottom: 4px;">${markerData.yardage} yards</td>
              </tr>
            </table>
          </div>
        </div>
      `;
    } else {
      // Create a styled info window for locations
      return `
        <div style="width: 280px; padding: 0; margin: 0; /* overflow: visible; */ font-family: system-ui, -apple-system, sans-serif; cursor: pointer;" 
             onclick="window.location.href='/locations/${markerData.id}'">
          <div style="height: 140px; overflow: hidden; position: relative;">
            <img src="${markerData.image_url}" alt="${markerData.name}" 
                 style="width: 100%; height: 100%; object-fit: cover;">
            <div style="position: absolute; top: 8px; right: 8px;">
              <span style="display: inline-block; background-color: rgba(255,255,255,0.8); border-radius: 50%; width: 24px; height: 24px; text-align: center; line-height: 24px; font-weight: bold; cursor: pointer;"
                    onclick="event.stopPropagation(); this.closest('.gm-style-iw-a').querySelector('.gm-ui-hover-effect').click();">×</span>
            </div>
            <div style="position: absolute; bottom: 0; right: 0; background-color: rgba(0,0,0,0.7); color: white; padding: 6px 10px;">
              <span style="font-size: 14px; font-weight: 600;">${markerData.name}</span>
            </div>
          </div>
          <div style="padding: 12px; background-color: white;">
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
          </div>
        </div>
      `;
    }
  }

  panMapToShowInfoWindow(infoWindow) {
    if (!this.map || !infoWindow) return;

    const mapDiv = this.map.getDiv();
    const infoWindowDiv = mapDiv.querySelector('.gm-style-iw'); // This selector might need adjustment

    if (!infoWindowDiv) {
      console.warn("Info window div not found for panning.");
      return;
    }

    const mapBounds = this.map.getBounds();
    if (!mapBounds) {
      console.warn("Map bounds not available for panning.");
      return; // Not enough info to pan yet
    }
    
    // Get the pixel position of the info window relative to the map container
    // The InfoWindow object itself doesn't directly expose its pixel bounds easily.
    // We rely on its content being in the DOM.
    const iwOuter = infoWindowDiv; // The main container of the info window
    const iwContainer = infoWindowDiv.firstChild; // The content container

    if (!iwOuter || !iwContainer) {
      console.warn("Info window inner elements not found for panning.");
      return;
    }

    const mapWidth = mapDiv.offsetWidth;
    const mapHeight = mapDiv.offsetHeight;

    // Get the position and size of the info window
    const iwRect = iwOuter.getBoundingClientRect(); // Relative to viewport
    const mapRect = mapDiv.getBoundingClientRect();   // Relative to viewport

    // Calculate iw top-left relative to map container
    const iwTop = iwRect.top - mapRect.top;
    const iwLeft = iwRect.left - mapRect.left;
    const iwWidth = iwRect.width;
    const iwHeight = iwRect.height;
    
    let panX = 0;
    let panY = 0;

    // Check horizontal visibility
    if (iwLeft < 0) {
      panX = iwLeft - 10; // Pan right (negative iwLeft), plus a margin
    } else if (iwLeft + iwWidth > mapWidth) {
      panX = (iwLeft + iwWidth - mapWidth) + 10; // Pan left, plus a margin
    }

    // Check vertical visibility
    // Note: InfoWindows usually open above the marker. We are more concerned about top cutoff here.
    if (iwTop < 0) {
      panY = iwTop - 10; // Pan down (negative iwTop), plus a margin
    } else if (iwTop + iwHeight > mapHeight) {
      // This case is less common for default InfoWindow behavior if it opens upwards.
      // But if it's a large info window or map is small.
      panY = (iwTop + iwHeight - mapHeight) + 10; // Pan up, plus a margin
    }
    
    if (panX !== 0 || panY !== 0) {
      console.log(typeof(panX), ' - ',typeof(panY));
      this.map.panBy(panX, panY);
    }

    // Ensure the overflow is visible after panning, as Google Maps might reset it.
    // It's also possible that the previous CSS for .gm-style-iw-d and .gm-style-iw-c 
    // with overflow: visible !important was too aggressive and caused issues,
    // so we apply it more targetedly here.
    if (iwContainer) {
        iwContainer.style.overflow = 'visible';
        iwContainer.parentElement.style.overflow = 'visible'; // .gm-style-iw-c or similar
    }
     // One final check to ensure the main info window wrapper is also visible
    const gmStyleIw = iwOuter.closest('.gm-style-iw');
    if (gmStyleIw) {
      gmStyleIw.style.overflow = 'visible';
    }
  }
}