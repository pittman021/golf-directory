//= require active_admin/base

document.addEventListener('DOMContentLoaded', function() {
  // Find all Cloudinary URL input fields and add an upload button next to them
  const cloudinaryFields = document.querySelectorAll('input[id$="_cloudinary_url"]');
  
  cloudinaryFields.forEach(function(field) {
    // Create a wrapper div for the input and button
    const wrapper = document.createElement('div');
    wrapper.className = 'cloudinary-field-wrapper';
    wrapper.style.display = 'flex';
    wrapper.style.alignItems = 'center';
    wrapper.style.gap = '10px';
    
    // Insert wrapper before the field
    field.parentNode.insertBefore(wrapper, field);
    
    // Move field into the wrapper
    wrapper.appendChild(field);
    
    // Create upload button
    const uploadButton = document.createElement('button');
    uploadButton.type = 'button';
    uploadButton.textContent = 'Upload Image';
    uploadButton.className = 'cloudinary-upload-button';
    uploadButton.style.padding = '5px 10px';
    uploadButton.style.backgroundColor = '#f0f0f0';
    uploadButton.style.border = '1px solid #ccc';
    uploadButton.style.borderRadius = '3px';
    uploadButton.style.cursor = 'pointer';
    
    // Add button to wrapper
    wrapper.appendChild(uploadButton);
    
    // Create a preview div
    const previewDiv = document.createElement('div');
    previewDiv.className = 'cloudinary-preview';
    previewDiv.style.marginTop = '10px';
    wrapper.parentNode.insertBefore(previewDiv, wrapper.nextSibling);
    
    // Update preview when URL changes
    field.addEventListener('input', function() {
      updatePreview(field.value, previewDiv);
    });
    
    // Show initial preview if URL exists
    updatePreview(field.value, previewDiv);
    
    // Handle upload button click
    uploadButton.addEventListener('click', function() {
      // Get cloudinary configuration from meta tags
      const cloudName = document.querySelector('meta[name="cloudinary-cloud-name"]')?.content;
      const uploadPreset = document.querySelector('meta[name="cloudinary-upload-preset"]')?.content;
      
      if (!cloudName || !uploadPreset) {
        alert('Cloudinary configuration is missing. Please check your environment variables.');
        return;
      }
      
      // Open Cloudinary upload widget
      cloudinary.openUploadWidget({
        cloudName: cloudName,
        uploadPreset: uploadPreset,
        sources: ['local', 'url', 'camera'],
        showAdvancedOptions: false,
        cropping: true,
        multiple: false,
        defaultSource: 'local',
        styles: {
          palette: {
            window: "#FFFFFF",
            sourceBg: "#F4F4F5",
            windowBorder: "#90a0b3",
            tabIcon: "#355E3B",
            inactiveTabIcon: "#69778A",
            menuIcons: "#355E3B",
            link: "#355E3B",
            action: "#355E3B",
            inProgress: "#355E3B",
            complete: "#355E3B",
            error: "#c43737",
            textDark: "#000000",
            textLight: "#FFFFFF"
          }
        }
      }, (error, result) => {
        if (!error && result && result.event === "success") {
          // Set the Cloudinary URL to the input field
          field.value = result.info.secure_url;
          // Update preview
          updatePreview(field.value, previewDiv);
        }
      });
    });
  });
  
  // Function to update the image preview
  function updatePreview(url, previewElement) {
    if (url && url.trim() !== '') {
      previewElement.innerHTML = `<img src="${url}" style="max-width: 200px; max-height: 150px; margin-top: 10px; border: 1px solid #ddd;">`;
    } else {
      previewElement.innerHTML = '';
    }
  }
});
