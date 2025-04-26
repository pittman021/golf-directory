# Configure ActiveStorage URL options
Rails.application.config.after_initialize do
  if Rails.env.production?
    ActiveStorage::Current.url_options = { host: 'www.golftriplist.com', protocol: 'https' }
  else
    ActiveStorage::Current.url_options = { host: 'localhost:3000', protocol: 'http' }
  end
end

# Ensure ActiveStorage is using Cloudinary
Rails.application.config.active_storage.service = :cloudinary 