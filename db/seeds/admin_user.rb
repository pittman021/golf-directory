# db/seeds/admin_user.rb
#
# This seed file only creates the admin user for ActiveAdmin
# without affecting any existing data

if AdminUser.count == 0 # Only create if no admin exists
  admin = AdminUser.create!(
    email: 'admin@golfdirectory.com',
    password: 'password123',
    password_confirmation: 'password123'
  )
  puts "Admin user created! Email: admin@golfdirectory.com, Password: password123"
  puts "Please change this password immediately after first login!"
else
  puts "AdminUser already exists - skipping creation"
end 