# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://golftriplist.com"

SitemapGenerator::Sitemap.create do
  # Add root path
  add root_path, :changefreq => 'daily', :priority => 1.0

  # Add courses
  Course.find_each do |course|
    add course_path(course), :lastmod => course.updated_at, :changefreq => 'weekly', :priority => 0.8
  end

  # Add locations
  Location.find_each do |location|
    add location_path(location), :lastmod => location.updated_at, :changefreq => 'weekly', :priority => 0.8
  end
end 