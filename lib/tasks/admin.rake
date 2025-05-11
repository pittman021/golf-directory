namespace :admin do
  desc "Create admin user for ActiveAdmin (for production use)"
  task create: :environment do
    if AdminUser.count == 0
      admin = AdminUser.create!(
        email: ENV['ADMIN_EMAIL'] || 'admin@golfdirectory.com',
        password: ENV['ADMIN_PASSWORD'] || 'password123',
        password_confirmation: ENV['ADMIN_PASSWORD'] || 'password123'
      )
      puts "Admin user created! Email: #{admin.email}"
      puts "Please change the password immediately after first login!"
    else
      puts "AdminUser already exists - skipping creation"
    end
  end
end 