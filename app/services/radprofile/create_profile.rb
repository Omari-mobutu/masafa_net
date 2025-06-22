# Example: Inserting into radcheck
module Radprofile
  class CreateProfile < ApplicationService
    def initialize(profile_data)
      @group_name = profile_data[:group_name]
      @rate_limit = profile_data[:rate_limit]
      @session_timeout = profile_data[:session_timeout]
      @idle_timeout = profile_data[:idle_timeout]
    end


    def call
      create_radius_profile
    end

  private

    def create_radius_profile
      # IMPORTANT: Sanitize your inputs to prevent SQL injection!
      # Use ActiveRecord's built-in sanitization or parameter binding.
      # For a simple string like username/password from your app,
      # ActiveRecord::Base.sanitize_sql_array is often the safest.

      # Hash the password if FreeRADIUS is configured to expect it (recommended!)
      # For example, using FreeRADIUS's crypt hash format:

      return false unless @group_name.present?

        # You can define a collection of attributes to insert based on your form data
        # This structure makes it easy to add more attributes later.
        attributes_to_insert = []

        if @rate_limit.present?
          attributes_to_insert << {
            attribute: "Mikrotik-Rate-Limit",
            op: ":=", # Use := for MikroTik VSAs to ensure override
            value: @rate_limit
          }
        end

        if @session_timeout.present?
          attributes_to_insert << {
            attribute: "Session-Timeout",
            op: "=",
            value: @session_timeout.to_s # RADIUS values are often strings
          }
        end

        if @idle_timeout.present?
          attributes_to_insert << {
            attribute: "Idle-Timeout",
            op: "=",
            value: @idle_timeout.to_s
          }
        end

        # If using Option B (flexible attributes_list):
        # @attributes_list.each do |attr_hash|
        #   attributes_to_insert << {
        #     attribute: attr_hash[:attribute],
        #     op: attr_hash[:op],
        #     value: attr_hash[:value]
        #   }
        # end

        if attributes_to_insert.empty?
          Rails.logger.warn "Attempted to create RADIUS profile '#{@group_name}' with no attributes."
          return false
        end

        # Use a transaction to ensure all inserts for a single group are atomic
        ActiveRecord::Base.connection.transaction do
          attributes_to_insert.each do |attr|
            sql = <<-SQL
              INSERT INTO radgroupreply (groupname, attribute, op, value)
              VALUES (?, ?, ?, ?)
            SQL
            ActiveRecord::Base.connection.execute(
              ActiveRecord::Base.send(:sanitize_sql_array, [
                sql,
                @group_name,
                attr[:attribute],
                attr[:op],
                attr[:value]
              ])
            )
          end
        end



      true # Indicate success


    rescue StandardError => e
      Rails.logger.error "Failed to create RADIUS user #{username}: #{e.message}"
      false # Indicate failure
    end


    # Usage example in your controller or service:
    # if create_radius_user("testuser123", "secure_password", "6Mbps_10KES")
    #   puts "RADIUS user created successfully!"
    # else
    #   puts "Failed to create RADIUS user."
    # end
  end
end
