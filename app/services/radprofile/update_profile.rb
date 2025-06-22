module Radprofile
  class UpdateProfile < ApplicationService
    def initialize(profile_data)
      # It's good practice to ensure the old_group_name is also passed if group_name can be changed,
      # but assuming group_name is the primary key and isn't changing for an update,
      # the current approach is fine. If group_name can change, you need both old and new.
      @group_name = profile_data[:group_name]
      @rate_limit = profile_data[:rate_limit]
      @session_timeout = profile_data[:session_timeout]
      @idle_timeout = profile_data[:idle_timeout]
      # @attributes_list = profile_data[:attributes_list] if using Option B
    end

    def call
      update_radius_profile
    end

    private

    def update_radius_profile
      return false unless @group_name.present?

      # Collect all attributes that should exist for this profile after the update
      new_attributes_for_group = []

      # Add predefined attributes from your form data
      if @rate_limit.present?
        new_attributes_for_group << {
          attribute: "Mikrotik-Rate-Limit",
          op: ":=", # Use := for MikroTik VSAs to ensure override
          value: @rate_limit
        }
      end

      if @session_timeout.present?
        new_attributes_for_group << {
          attribute: "Session-Timeout",
          op: "=",
          value: @session_timeout.to_s
        }
      end

      if @idle_timeout.present?
        new_attributes_for_group << {
          attribute: "Idle-Timeout",
          op: "=",
          value: @idle_timeout.to_s
        }
      end

      # If using Option B (flexible attributes_list):
      # @attributes_list.each do |attr_hash|
      #   new_attributes_for_group << {
      #     attribute: attr_hash[:attribute],
      #     op: attr_hash[:op],
      #     value: attr_hash[:value]
      #   }
      # end

      # It's okay if new_attributes_for_group is empty; it means the profile will have no attributes.
      # If you want to prevent empty profiles, add a check here.
      # if new_attributes_for_group.empty?
      #   Rails.logger.warn "Attempted to update RADIUS profile '#{@group_name}' with no attributes. Consider if this is desired behavior."
      #   # return false # Or handle as an error if empty profiles are not allowed
      # end

      ActiveRecord::Base.connection.transaction do
        # 1. Delete all existing attributes for this groupname
        delete_sql = <<-SQL
          DELETE FROM radgroupreply
          WHERE groupname = ?
        SQL
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.send(:sanitize_sql_array, [ delete_sql, @group_name ])
        )

        # 2. Insert the new set of attributes for this groupname
        new_attributes_for_group.each do |attr|
          insert_sql = <<-SQL
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES (?, ?, ?, ?)
          SQL
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.send(:sanitize_sql_array, [
              insert_sql,
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
      Rails.logger.error "Failed to update RADIUS profile '#{@group_name}': #{e.message}"
      false # Indicate failure
    end
  end
end
