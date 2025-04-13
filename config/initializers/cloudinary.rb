require 'cloudinary'

# Configure Cloudinary
Cloudinary.config do |config|
  config.cloud_name = Rails.application.credentials.cloudinary[:cloud_name]
  config.api_key = Rails.application.credentials.cloudinary[:api_key]
  config.api_secret = Rails.application.credentials.cloudinary[:api_secret]
  config.secure = true
  config.cdn_subdomain = true
end

# Log to confirm configuration
Rails.logger.info "Cloudinary configured with cloud_name: #{Cloudinary.config.cloud_name}" 