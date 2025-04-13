class CloudinaryService
  def self.upload(file, options = {})
    return nil unless file.present?
    
    # Set default options
    default_options = {
      folder: 'golf_directory',
      resource_type: 'auto'
    }
    
    # Merge with provided options
    options = default_options.merge(options)
    
    begin
      # Upload to Cloudinary
      response = Cloudinary::Uploader.upload(file, options)
      
      # Return the secure URL
      response['secure_url']
    rescue => e
      Rails.logger.error "Cloudinary upload error: #{e.message}"
      nil
    end
  end
  
  def self.destroy(public_id)
    return false unless public_id.present?
    
    begin
      Cloudinary::Uploader.destroy(public_id)
      true
    rescue => e
      Rails.logger.error "Cloudinary delete error: #{e.message}"
      false
    end
  end
  
  def self.extract_public_id(url)
    return nil unless url.present? && url.include?('cloudinary')
    
    # Extract public ID from Cloudinary URL
    uri = URI.parse(url)
    path = uri.path
    
    # Find the position after /upload/ in the path
    upload_idx = path.index('/upload/')
    return nil unless upload_idx
    
    # Extract everything after /upload/ excluding the file extension
    public_id = path[(upload_idx + 8)..-1]
    public_id = public_id.split('.').first
    
    public_id
  end
end 