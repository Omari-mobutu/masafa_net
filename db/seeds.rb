# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb

# Clear existing subscriptions (optional, be careful in production!)
Subscription.destroy_all

# Get existing FreeRADIUS group names for linking
# In a real app, you might fetch this dynamically or ensure manual consistency
# For seeding, hardcoding is often fine if you've already created them.

# Example FreeRADIUS group names you created:
# "6Mbps_10KES"
# "10Mbps_20KES"
# "Unlimited_Hour"

Subscription.create!([
  {
    name: "Basic 6Mbps Hotspot (1 Hour)",
    description: "Enjoy 1 hour of internet access at 6 Mbps.",
    price: 10.00, # KES
    duration_minutes: 60,
    freeradius_group_name: "6Mbps_@10_bob" # MUST match a groupname in radgroupreply
  },
  {
    name: "Standard 8Mbps Hotspot (3 Hours)",
    description: "Faster internet for 3 hours at 10 Mbps.",
    price: 25.00, # KES
    duration_minutes: 180,
    freeradius_group_name: "8Mbps_@25_bob"
  },
  {
    name: "Premium internet @20Mbps",
    description: "Premium internet @20Mbps for 2 hours.",
    price: 40.00, # KES
    duration_minutes: 120,
    freeradius_group_name: "20Mbps_@40_bob" # Or whatever your 24hr profile is called
  }
])

puts "Seeded #{Subscription.count} subscriptions."
