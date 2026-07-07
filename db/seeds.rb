# Create Roles
super_admin = Role.find_or_create_by!(name: "Super Admin")
admin = Role.find_or_create_by!(name: "Admin")
supervisor = Role.find_or_create_by!(name: "Supervisor")

# Create default Super Admin user
User.find_or_create_by!(email: "admin@financeerp.com") do |user|
  user.name = "Super Admin"
  user.phone = "9999999999"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = super_admin
end

puts "Seed data created successfully!"
puts "Login with: admin@financeerp.com / password123"
