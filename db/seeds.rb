puts "Seeding Kuposu Bus Management..."

# Default Branch
branch = Branch.find_or_create_by!(code: "HQ") do |b|
  b.name = "Head Office"
  b.city = "Bangalore"
  b.state = "Karnataka"
  b.state_code = "29"
  b.is_default = true
  b.active = true
end

# Default Warehouse
Warehouse.find_or_create_by!(name: "Main Store") do |w|
  w.branch = branch
  w.is_default = true
  w.active = true
end

# Admin user
admin = User.find_or_initialize_by(email: "admin@busservicepro.com")
admin.name = "Admin"
admin.password = "password123"
admin.password_confirmation = "password123"
admin.branch = branch
admin.save!

# Create admin role if Role model exists
if defined?(Role) && Role.respond_to?(:find_or_create_by!)
  role = Role.find_or_create_by!(name: "Super Admin")
  admin.update(role: role) if admin.respond_to?(:role=)
end

# Service Types
["Periodic Maintenance", "Engine Overhaul", "Brake Service", "Electrical Repair",
 "AC Service", "Body & Paint", "Tyre Service", "General Repair"].each_with_index do |name, i|
  ServiceType.find_or_create_by!(name: name) do |st|
    st.active = true
    st.sort_order = i
  end
end

puts "Seeding complete!"
