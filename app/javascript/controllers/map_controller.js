import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "markers", "card", "mapElement"]
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
  
  debugConnection() {
    console.log("Map controller debug connection");
    console.log("Element:", this.element);
    console.log("Map element:", this.mapElementTarget);
    console.log("Has markers value:", this.hasMarkersValue);
    if (this.hasMarkersValue) {
      console.log("Markers data:", this.markersValue);
    }
    console.log("Card targets:", this.cardTargets);
  }
  
  debugCard(event) {
    console.log("Card connected:", event.currentTarget);
    console.log("Course ID:", event.currentTarget.dataset.courseId);
  }
  
  testHover(event) {
    console.log("Hover event triggered:", event.type);
    console.log("Target:", event.currentTarget);
    console.log("Course ID:", event.currentTarget.dataset.courseId);
    alert(`Hover ${event.type} on course ${event.currentTarget.dataset.courseId}`);
  }
  
  highlightMarkerOnHover(event) {
    const courseId = event.currentTarget.dataset.courseId;
    if (!courseId) return;
    
    // Find the marker for this course
    const markerIndex = this.markersValue.findIndex(marker => marker.id.toString() === courseId.toString());
    
    if (markerIndex >= 0 && this.markers && this.infoWindows) {
      const marker = this.markers[markerIndex];
      const infoWindow = this.infoWindows[markerIndex];
      
      // Close all info windows first
      this.infoWindows.forEach(info => info.close());
      
      // Open this info window
      if (infoWindow && marker) {
        infoWindow.open(this.map, marker);
      }
    }
  }
  
  resetMarkerOnHover(event) {
    const courseId = event.currentTarget.dataset.courseId;
    if (!courseId) return;
    
    // Find the marker for this course
    const markerIndex = this.markersValue.findIndex(marker => marker.id.toString() === courseId.toString());
    
    if (markerIndex >= 0 && this.markers && this.infoWindows) {
      const infoWindow = this.infoWindows[markerIndex];
      
      // Close the info window
      if (infoWindow) {
        infoWindow.close();
      }
    }
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
      
      
      // Initialize the map on the mapElement target instead of this.element
      this.map = new google.maps.Map(this.mapElementTarget, {
        center: { lat, lng },
        zoom: zoom,
        mapId: window.googleMapsConfig?.mapId,
        mapTypeControl: false,
        fullscreenControl: false,
        streetViewControl: false
      });
      
      this.mapElementTarget.style.backgroundColor = "#e5e5e5";
      
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
      console.log("Markers data:", markersData);
      const bounds = new google.maps.LatLngBounds();
      
      // Store markers and info windows
      this.markers = [];
      this.infoWindows = [];
      
      markersData.forEach((markerData, index) => {
        console.log(`Processing marker ${index}:`, markerData);
        console.log(`Marker type: ${markerData.type}`);
        
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
          disableAutoPan: true,
          ariaLabel: markerData.name
        });
        
        this.infoWindows.push(infoWindow);
        
        // Use Advanced Marker if available, fall back to regular Marker if not
        let marker;
        
        if (google.maps.marker && google.maps.marker.AdvancedMarkerElement) {
          console.log("Using Advanced Marker API");
          // Create custom marker content based on type
          const markerContent = document.createElement('div');
          markerContent.className = 'custom-marker';
          
          if (markerData.type === 'location') {
            console.log("Creating location marker");
            markerContent.innerHTML = `
              <div class="location-marker">
                <svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <circle cx="16" cy="16" r="16" fill="#355E3B"/>
                  <circle cx="16" cy="16" r="8" fill="white"/>
                </svg>
              </div>
            `;
          } else {
            markerContent.innerHTML = `
              <div class="course-marker">
              <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
                <g fill="none">
                  <path
                    d="M16 0C9.37 0 4 5.37 4 12c0 7.25 10.4 19.33 11.1 20.17a1 1 0 0 0 1.8 0C17.6 31.33 28 19.25 28 12c0-6.63-5.37-12-12-12Z"
                    fill="#E53E3E"
                  />
                  <circle cx="16" cy="12" r="5" fill="white"/>
                  <path
                    d="M17 9l4 2-4 2v-4Z"
                    fill="#1A202C"
                  />
                  <line x1="17" y1="9" x2="17" y2="15" stroke="#1A202C" stroke-width="1.5"/>
                </g>
              </svg>
            </div>
            `;
          }
          
          // Use the new AdvancedMarkerElement
          marker = new google.maps.marker.AdvancedMarkerElement({
            map: this.map,
            position: position,
            title: markerData.name,
            content: markerContent
          });
          
          // For advanced markers, we need to add click listeners differently
          marker.addListener('click', () => {
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
              }, 100);
            });
            
            // Trigger marker click event
            this.markerClicked(markerData.id);
          });
        } else {
          // Fall back to legacy Marker with custom icon
          const icon = {
            url: markerData.type === 'location' 
              ? 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIxNiIgY3k9IjE2IiByPSIxNiIgZmlsbD0iIzM1NUUzQiIvPjxjaXJjbGUgY3g9IjE2IiBjeT0iMTYiIHI9IjgiIGZpbGw9IndoaXRlIi8+PC9zdmc+'
              : 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkwxMiAxMkwyMiA3TDEyIDJaIiBmaWxsPSIjRTUzRTNFIi8+PHBhdGggZD0iTTIgMTdMMTIgMjJMMjIgMTciIHN0cm9rZT0iI0U1M0UzRSIgc3Ryb2tlLXdpZHRoPSIyIi8+PC9zdmc+',
            scaledSize: new google.maps.Size(32, 32),
            anchor: new google.maps.Point(16, 16)
          };
          
          marker = new google.maps.Marker({
            position: position,
            map: this.map,
            title: markerData.name,
            icon: icon
          });
          
          // Add click listener
          marker.addListener('click', () => {
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
              }, 100);
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
    // Rectangle layout, image left, text right
    const isCourse = markerData.type === 'course';
    const linkPath = isCourse ? `/courses/${markerData.id}` : `/locations/${markerData.id}`;
    const imageUrl = markerData.image_url || (isCourse ? '/placeholder_golf_course.jpg' : '/placeholder_golf_course.jpg');
    const name = markerData.name;
    // Always use state for subtext if available
    const stateName = markerData.state || '';
    let details = '';
    if (isCourse) {
      details = `${markerData.course_type || ''}${markerData.green_fee ? ` • ${markerData.green_fee}` : ''}`;
    } else {
      details = `${markerData.courses_count} course${markerData.courses_count == 1 ? '' : 's'}${markerData.avg_green_fee ? ` • Avg ${markerData.avg_green_fee}` : ''}${markerData.estimated_trip_cost ? ` • ${markerData.estimated_trip_cost}` : ''}`;
    }
    return `
      <div style="display: flex; flex-direction: row; align-items: stretch; width: 340px; min-height: 110px; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 7px 1px rgba(0,0,0,0.13); cursor: pointer;" onclick=\"window.location.href='${linkPath}'\">
        <div style=\"flex: 0 0 110px; height: 110px; background: #eee; display: flex; align-items: stretch;\">
          <img src=\"${imageUrl}\" alt=\"${name}\" style=\"width: 110px; height: 110px; object-fit: cover; display: block; margin: 0; padding: 0;\">
        </div>
        <div style=\"flex: 1 1 0%; padding: 10px 16px 10px 16px; display: flex; flex-direction: column; justify-content: center;\">
          <div style=\"font-weight: bold; font-size: 1.08rem; color: #222; margin-bottom: 2px; margin-top: 0; text-align: left;\">${name}</div>
          <div style=\"color: #bbb; font-size: 0.93rem; margin-bottom: 6px; text-align: left;\">${stateName}</div>
          <div style=\"color: #444; font-size: 0.97rem; text-align: left;\">${details}</div>
        </div>
      </div>
    `;
  }

  panMapToShowInfoWindow(infoWindow) {
    if (!this.map || !infoWindow) return;

    // Wait a bit for DOM to be fully ready
    setTimeout(() => {
      try {
        const mapDiv = this.map.getDiv();
        if (!mapDiv) {
          console.warn("Map div not found for panning.");
          return;
        }

        const infoWindowDiv = mapDiv.querySelector('.gm-style-iw');
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
        const iwOuter = infoWindowDiv; // The main container of the info window
        const iwContainer = infoWindowDiv.firstChild; // The content container

        if (!iwOuter || !iwContainer) {
          console.warn("Info window inner elements not found for panning.");
          return;
        }

        // Verify elements are actually DOM Elements before proceeding
        if (!(iwOuter instanceof Element) || !(iwContainer instanceof Element)) {
          console.warn("Info window elements are not valid DOM Elements.");
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
        if (iwTop < 0) {
          panY = iwTop - 10; // Pan down (negative iwTop), plus a margin
        } else if (iwTop + iwHeight > mapHeight) {
          panY = (iwTop + iwHeight - mapHeight) + 10; // Pan up, plus a margin
        }
        
        if (panX !== 0 || panY !== 0) {
          console.log(`Panning map by ${panX}, ${panY}`);
          this.map.panBy(panX, panY);
        }

        // Ensure the overflow is visible after panning
        if (iwContainer instanceof Element) {
          iwContainer.style.overflow = 'visible';
          if (iwContainer.parentElement instanceof Element) {
            iwContainer.parentElement.style.overflow = 'visible';
          }
        }
        
        // One final check to ensure the main info window wrapper is also visible
        const gmStyleIw = iwOuter.closest('.gm-style-iw');
        if (gmStyleIw instanceof Element) {
          gmStyleIw.style.overflow = 'visible';
        }
      } catch (error) {
        console.error("Error when panning map to show info window:", error);
      }
    }, 100); // Short delay to ensure DOM is fully ready
  }

  highlightMarker(event) {
    console.log("Highlight marker called", event);
    const courseId = event.currentTarget.dataset.courseId;
    console.log("Course ID:", courseId);
    
    if (!courseId) {
      console.log("No course ID found");
      return;
    }
    
    // Find the marker for this course
    const markerIndex = this.markersValue.findIndex(marker => marker.id.toString() === courseId.toString());
    console.log("Marker index:", markerIndex);
    
    if (markerIndex >= 0 && this.markers && this.infoWindows) {
      const marker = this.markers[markerIndex];
      const infoWindow = this.infoWindows[markerIndex];
      
      // Close all info windows first
      this.infoWindows.forEach(info => info.close());
      
      // Open this info window
      if (infoWindow && marker) {
        console.log("Opening info window");
        infoWindow.open(this.map, marker);
      }
    }
  }

  resetMarker(event) {
    console.log("Reset marker called", event);
    const courseId = event.currentTarget.dataset.courseId;
    console.log("Course ID:", courseId);
    
    if (!courseId) {
      console.log("No course ID found");
      return;
    }
    
    // Find the marker for this course
    const markerIndex = this.markersValue.findIndex(marker => marker.id.toString() === courseId.toString());
    console.log("Marker index:", markerIndex);
    
    if (markerIndex >= 0 && this.markers && this.infoWindows) {
      const infoWindow = this.infoWindows[markerIndex];
      
      // Close the info window
      if (infoWindow) {
        console.log("Closing info window");
        infoWindow.close();
      }
    }
  }

  // Generic hover methods that work for both courses and locations
  highlightMarkerOnHoverGeneric(event) {
    const itemId = event.currentTarget.dataset.courseId || event.currentTarget.dataset.locationId;
    if (!itemId) return;
    
    // Find the marker for this item
    const markerIndex = this.markersValue.findIndex(marker => marker.id.toString() === itemId.toString());
    
    if (markerIndex >= 0 && this.markers && this.infoWindows) {
      const marker = this.markers[markerIndex];
      const infoWindow = this.infoWindows[markerIndex];
      
      // Close all info windows first
      this.infoWindows.forEach(info => info.close());
      
      // Open this info window
      if (infoWindow && marker) {
        infoWindow.open(this.map, marker);
      }
    }
  }

  resetMarkerOnHoverGeneric(event) {
    const itemId = event.currentTarget.dataset.courseId || event.currentTarget.dataset.locationId;
    if (!itemId) return;
    
    // Find the marker for this item
    const markerIndex = this.markersValue.findIndex(marker => marker.id.toString() === itemId.toString());
    
    if (markerIndex >= 0 && this.markers && this.infoWindows) {
      const infoWindow = this.infoWindows[markerIndex];
      
      // Close the info window
      if (infoWindow) {
        infoWindow.close();
      }
    }
  }
}