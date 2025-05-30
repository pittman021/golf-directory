import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "markers", "card", "mapElement"]
  static values = {
    latitude: Number,
    longitude: Number,
    markers: Array
  }
  
  connect() {
    // Make this controller globally accessible for info window close buttons
    window.mapController = this;
    // Set a timer to check if Google Maps API is loaded
    this.checkGoogleMapsLoaded();
  }
  
  disconnect() {
    // Clean up global reference
    if (window.mapController === this) {
      window.mapController = null;
    }
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
      /* Constrain info windows to map container */
      .gm-style .gm-style-iw-c {
        padding: 0 !important;
        max-height: none !important;
        box-shadow: 0 2px 7px 1px rgba(0,0,0,0.3);
        border-radius: 8px !important;
        z-index: 1 !important; /* Keep within map container z-index */
      }
      
      .gm-style .gm-style-iw-d {
        max-height: none !important;
        overflow: hidden !important; /* Prevent overflow outside map */
      }
      
      /* Hide scrollbars */
      .gm-style-iw-d::-webkit-scrollbar { 
        display: none;
      }
      
      /* Hide default close button and tail */
      .gm-ui-hover-effect {
        display: none !important;
      }
      
      .gm-style-iw-tc, .gm-style-iw-tc:after {
        display: none !important;
      }
      
      /* Ensure map container has proper stacking context */
      .map-container {
        position: relative;
        z-index: 1;
        overflow: hidden; /* Constrain all map content */
      }
      
      /* Ensure info windows don't escape map bounds */
      .gm-style-iw {
        max-width: calc(100vw - 2rem) !important;
        max-height: calc(100vh - 4rem) !important;
      }
    `;
    document.head.appendChild(style);
    
    // Add event listener to catch any dynamically created info windows
    google.maps.event.addListener(this.map, 'idle', () => {
      // Ensure all info windows stay within bounds
      const infoWindows = document.querySelectorAll('.gm-style-iw, .gm-style-iw-d');
      infoWindows.forEach(el => {
        el.style.maxHeight = 'calc(100vh - 4rem)';
        // Keep overflow hidden to prevent escaping map container
        el.style.overflow = 'hidden';
      });
    });
  }
  
  addMarkers() {
    try {
      const markersData = this.markersValue;
      const bounds = new google.maps.LatLngBounds();
      
      // Store markers and info windows
      this.markers = [];
      this.infoWindows = [];
      
      markersData.forEach((markerData, index) => {
        // Ensure latitude and longitude are valid numbers
        const latitude = parseFloat(markerData.latitude);
        const longitude = parseFloat(markerData.longitude);

        // Skip invalid coordinates
        if (isNaN(latitude) || isNaN(longitude)) {
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
          // Create custom marker content based on type
          const markerContent = document.createElement('div');
          markerContent.className = 'custom-marker';
          
          if (markerData.type === 'location') {
            markerContent.innerHTML = `
              <div class="location-marker">
                <svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <circle cx="16" cy="16" r="16" fill="#355E3B"/>
                  <circle cx="16" cy="16" r="8" fill="white"/>
                </svg>
              </div>
            `;
          } else {
            // Use different markers based on course type
            markerContent.innerHTML = this.getCourseMarkerSVG(markerData.course_type);
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
          // Fall back to legacy Marker with custom icon using course type specific designs
          const locationSvg = `<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
            <circle cx="16" cy="16" r="16" fill="#355E3B"/>
            <circle cx="16" cy="16" r="8" fill="white"/>
          </svg>`;
          
          // Get course type specific SVG for legacy markers
          const courseSvg = this.getLegacyCourseMarkerSVG(markerData.course_type);
          
          const icon = {
            url: markerData.type === 'location' 
              ? 'data:image/svg+xml;base64,' + btoa(locationSvg)
              : 'data:image/svg+xml;base64,' + btoa(courseSvg),
            scaledSize: new google.maps.Size(40, 40),
            anchor: new google.maps.Point(20, 40) // Anchor at bottom center for pin
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
      <div style="position: relative; display: flex; flex-direction: row; align-items: stretch; width: 340px; min-height: 110px; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 7px 1px rgba(0,0,0,0.13); cursor: pointer;" onclick=\"window.location.href='${linkPath}'\">
        <button onclick="event.stopPropagation(); window.mapController.closeAllInfoWindows();" style="position: absolute; top: 8px; right: 8px; width: 24px; height: 24px; border: none; background: rgba(0,0,0,0.6); color: white; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: bold; z-index: 10; line-height: 1;" title="Close">×</button>
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
          return;
        }

        const infoWindowDiv = mapDiv.querySelector('.gm-style-iw');
        if (!infoWindowDiv) {
          return;
        }

        const mapBounds = this.map.getBounds();
        if (!mapBounds) {
          return; // Not enough info to pan yet
        }
        
        // Get the pixel position of the info window relative to the map container
        const iwOuter = infoWindowDiv; // The main container of the info window
        const iwContainer = infoWindowDiv.firstChild; // The content container

        if (!iwOuter || !iwContainer) {
          return;
        }

        // Verify elements are actually DOM Elements before proceeding
        if (!(iwOuter instanceof Element) || !(iwContainer instanceof Element)) {
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

        // Check horizontal visibility - be more conservative
        if (iwLeft < 20) {
          panX = iwLeft - 20; // Pan right, with margin
        } else if (iwLeft + iwWidth > mapWidth - 20) {
          panX = (iwLeft + iwWidth - mapWidth) + 20; // Pan left, with margin
        }

        // Check vertical visibility - be more conservative  
        if (iwTop < 20) {
          panY = iwTop - 20; // Pan down, with margin
        } else if (iwTop + iwHeight > mapHeight - 20) {
          panY = (iwTop + iwHeight - mapHeight) + 20; // Pan up, with margin
        }
        
        // Only pan if necessary and keep it minimal
        if (panX !== 0 || panY !== 0) {
          this.map.panBy(panX, panY);
        }

        // Ensure the info window stays constrained within map bounds
        if (iwContainer instanceof Element) {
          iwContainer.style.overflow = 'hidden'; // Keep constrained
          iwContainer.style.maxHeight = 'calc(100vh - 4rem)';
          if (iwContainer.parentElement instanceof Element) {
            iwContainer.parentElement.style.overflow = 'hidden';
            iwContainer.parentElement.style.maxHeight = 'calc(100vh - 4rem)';
          }
        }
        
        // Ensure the main info window wrapper stays constrained
        const gmStyleIw = iwOuter.closest('.gm-style-iw');
        if (gmStyleIw instanceof Element) {
          gmStyleIw.style.overflow = 'hidden';
          gmStyleIw.style.maxHeight = 'calc(100vh - 4rem)';
        }
      } catch (error) {
        // Silently handle errors
      }
    }, 100); // Short delay to ensure DOM is fully ready
  }

  highlightMarker(event) {
    const courseId = event.currentTarget.dataset.courseId;
    
    if (!courseId) {
      return;
    }
    
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

  resetMarker(event) {
    const courseId = event.currentTarget.dataset.courseId;
    
    if (!courseId) {
      return;
    }
    
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

  getCourseMarkerSVG(courseType) {
    const courseTypeNormalized = courseType ? courseType.toLowerCase() : 'public course';
    
    switch (courseTypeNormalized) {
      case 'public course':
      case 'public':
        return `
          <div class="course-marker">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- Pin shape - Dark green for public -->
              <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#1B4332"/>
              <!-- Golf tee icon -->
              <g transform="translate(15, 8)">
                <path d="M5 7v10" stroke="white" stroke-width="2" stroke-linecap="round"/>
                <path d="M2.5 17h5" stroke="white" stroke-width="2" stroke-linecap="round"/>
                <circle cx="5" cy="6" r="2" fill="white"/>
              </g>
            </svg>
          </div>
        `;
        
      case 'private course':
      case 'private':
        return `
          <div class="course-marker">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- Pin shape - Dark blue for private -->
              <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#1E3A8A"/>
              <!-- Lock icon -->
              <g transform="translate(13, 7)">
                <rect x="2.5" y="7.5" width="7.5" height="5" rx="0.5" stroke="white" stroke-width="1.5" fill="none"/>
                <path d="M4.5 7.5V5.5a2 2 0 114 0v2" stroke="white" stroke-width="1.5" fill="none"/>
                <circle cx="6.25" cy="10" r="0.75" fill="white"/>
              </g>
            </svg>
          </div>
        `;
        
      case 'resort course':
      case 'resort':
        return `
          <div class="course-marker">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- Pin shape - Gold for resort -->
              <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#D4AF37"/>
              <!-- Resort building icon -->
              <g transform="translate(13, 7)">
                <path d="M1 12.5h12v-5l-6-3.75-6 3.75v5z" stroke="white" stroke-width="1.5" fill="none"/>
                <path d="M5 12.5v-3.75h4v3.75" stroke="white" stroke-width="1.5"/>
                <circle cx="7" cy="10.5" r="0.4" fill="white"/>
              </g>
            </svg>
          </div>
        `;
        
      case 'semi-private course':
      case 'semi-private':
        return `
          <div class="course-marker">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- Pin shape - Medium green for semi-private -->
              <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#2D5016"/>
              <!-- Half-open gate icon -->
              <g transform="translate(13, 7)">
                <path d="M1 5v7.5h2.5V5M10.5 5v7.5H13V5" stroke="white" stroke-width="1.5"/>
                <path d="M3.5 8.75h3" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
                <path d="M10.5 8.75h1.25" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
              </g>
            </svg>
          </div>
        `;
        
      case 'municipal course':
      case 'municipal':
        return `
          <div class="course-marker">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- Pin shape - Dark teal for municipal -->
              <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#134E4A"/>
              <!-- City building icon -->
              <g transform="translate(13, 7)">
                <rect x="1" y="7.5" width="3.75" height="5" stroke="white" stroke-width="1.5" fill="none"/>
                <rect x="7.5" y="5" width="3.75" height="7.5" stroke="white" stroke-width="1.5" fill="none"/>
                <rect x="2.25" y="8.75" width="1.25" height="1.25" fill="white"/>
                <rect x="8.75" y="6.25" width="1.25" height="1.25" fill="white"/>
                <rect x="8.75" y="8.75" width="1.25" height="1.25" fill="white"/>
              </g>
            </svg>
          </div>
        `;
        
      default:
        // Default golf course marker (dark green)
        return `
          <div class="course-marker">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <!-- Pin shape - Default dark green -->
              <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#1B4332"/>
              <!-- Golf flag inside pin -->
              <g transform="translate(15, 7)">
                <path d="M2.5 2.5v15" stroke="white" stroke-width="2" stroke-linecap="round"/>
                <path d="M2.5 2.5l7.5 2.5-7.5 2.5V2.5z" fill="white"/>
              </g>
            </svg>
          </div>
        `;
    }
  }

  getLegacyCourseMarkerSVG(courseType) {
    const courseTypeNormalized = courseType ? courseType.toLowerCase() : 'public course';
    
    switch (courseTypeNormalized) {
      case 'public course':
      case 'public':
        return `<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#1B4332"/>
          <g transform="translate(15, 8)">
            <path d="M5 7v10" stroke="white" stroke-width="2" stroke-linecap="round"/>
            <path d="M2.5 17h5" stroke="white" stroke-width="2" stroke-linecap="round"/>
            <circle cx="5" cy="6" r="2" fill="white"/>
          </g>
        </svg>`;
        
      case 'private course':
      case 'private':
        return `<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#1E3A8A"/>
          <g transform="translate(13, 7)">
            <rect x="2.5" y="7.5" width="7.5" height="5" rx="0.5" stroke="white" stroke-width="1.5" fill="none"/>
            <path d="M4.5 7.5V5.5a2 2 0 114 0v2" stroke="white" stroke-width="1.5" fill="none"/>
            <circle cx="6.25" cy="10" r="0.75" fill="white"/>
          </g>
        </svg>`;
        
      case 'resort course':
      case 'resort':
        return `<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#D4AF37"/>
          <g transform="translate(13, 7)">
            <path d="M1 12.5h12v-5l-6-3.75-6 3.75v5z" stroke="white" stroke-width="1.5" fill="none"/>
            <path d="M5 12.5v-3.75h4v3.75" stroke="white" stroke-width="1.5"/>
            <circle cx="7" cy="10.5" r="0.4" fill="white"/>
          </g>
        </svg>`;
        
      case 'semi-private course':
      case 'semi-private':
        return `<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#2D5016"/>
          <g transform="translate(13, 7)">
            <path d="M1 5v7.5h2.5V5M10.5 5v7.5H13V5" stroke="white" stroke-width="1.5"/>
            <path d="M3.5 8.75h3" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
            <path d="M10.5 8.75h1.25" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
          </g>
        </svg>`;
        
      case 'municipal course':
      case 'municipal':
        return `<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#134E4A"/>
          <g transform="translate(13, 7)">
            <rect x="1" y="7.5" width="3.75" height="5" stroke="white" stroke-width="1.5" fill="none"/>
            <rect x="7.5" y="5" width="3.75" height="7.5" stroke="white" stroke-width="1.5" fill="none"/>
            <rect x="2.25" y="8.75" width="1.25" height="1.25" fill="white"/>
            <rect x="8.75" y="6.25" width="1.25" height="1.25" fill="white"/>
            <rect x="8.75" y="8.75" width="1.25" height="1.25" fill="white"/>
          </g>
        </svg>`;
        
      default:
        // Default golf course marker (dark green)
        return `<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M20 2C14.48 2 10 6.48 10 12c0 7.5 10 22.5 10 22.5s10-15 10-22.5c0-5.52-4.48-10-10-10z" fill="#1B4332"/>
          <g transform="translate(15, 7)">
            <path d="M2.5 2.5v15" stroke="white" stroke-width="2" stroke-linecap="round"/>
            <path d="M2.5 2.5l7.5 2.5-7.5 2.5V2.5z" fill="white"/>
          </g>
        </svg>`;
    }
  }

  closeAllInfoWindows() {
    if (this.infoWindows) {
      this.infoWindows.forEach(info => info.close());
    }
  }
}