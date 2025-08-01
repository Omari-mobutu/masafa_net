# lib/tasks/gift_subscriptions.rake
namespace :gifts do
  desc "Creates gifted subscriptions for eligible existing clients"
  task create_loyalty_gifts: :environment do
    puts "Starting the loyalty gift creation process..."

    # Define the target date (August 1st, 2025)
    target_date = Date.new(2025, 8, 1)

    # --- Step 1: Find eligible users by MAC address ---
    # Assuming 'PaymentTransaction' is the model that records MAC addresses.
    # This query finds all MAC addresses and counts their occurrences.
    mac_address_counts = PaymentTransaction
      .where("created_at < ?", target_date)
      .group(:client_mac)
      .count

    # --- Step 2: Separate users into two groups ---
    frequent_users = mac_address_counts.select { |mac, count| count > 1 }
    standard_users = mac_address_counts.select { |mac, count| count == 1 }

    # Define the package names for gifting
    higher_package = "8Mbps_@25_bob"
    standard_package = "6Mbps_@10_bob"

    # --- Step 3: Create gifts for frequent users (Higher Package) ---
    puts "Gifting the '#{higher_package}' to #{frequent_users.count} frequent users..."
    frequent_users.each do |mac_address, _count|
      next if GiftedSubscription.exists?(mac_address: mac_address) # Skip if already gifted

      # Create username and password based on your criteria
      generated_username = "user_#{SecureRandom.alphanumeric(8).downcase}"
      generated_password = SecureRandom.base64(12)

      # Create the user on the Radius server
      if Radprofile::CreateUser.call(generated_username, generated_password, higher_package)
        GiftedSubscription.create!(
          mac_address: mac_address,
          package_name: higher_package,
          username: generated_username,
          password: generated_password
        )
        puts "  -> Successfully gifted a '#{higher_package}' to MAC address: #{mac_address}"
      else
        puts "  -> FAILED to create Radius user for MAC address: #{mac_address}"
      end
    end

    # --- Step 4: Create gifts for standard users (Standard Package) ---
    puts "\nGifting the '#{standard_package}' to #{standard_users.count} standard users..."
    standard_users.each do |mac_address, _count|
      next if GiftedSubscription.exists?(mac_address: mac_address) # Skip if already gifted

      # Create username and password
      generated_username = "user_#{SecureRandom.alphanumeric(8).downcase}"
      generated_password = SecureRandom.base64(12)

      # Create the user on the Radius server
      if Radprofile::CreateUser.call(generated_username, generated_password, standard_package)
        GiftedSubscription.create!(
          mac_address: mac_address,
          package_name: standard_package,
          username: generated_username,
          password: generated_password
        )
        puts "  -> Successfully gifted a '#{standard_package}' to MAC address: #{mac_address}"
      else
        puts "  -> FAILED to create Radius user for MAC address: #{mac_address}"
      end
    end

    puts "\nGift creation process completed."
  end
end
