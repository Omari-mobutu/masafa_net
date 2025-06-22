module Radprofile
  class GetProfiles
    def self.all_profiles # Use a class method for fetching all
      sql = <<-SQL
        SELECT groupname, attribute, op, value
        FROM radgroupreply
        ORDER BY groupname, attribute
      SQL

      results = ActiveRecord::Base.connection.select_all(sql)

      # Process results into a more convenient hash structure
      # { "ProfileName1" => [{attribute: "...", op: "...", value: "..."}, ...],
      #   "ProfileName2" => [...] }
      grouped_profiles = {}
      results.each do |row|
        group_name = row["groupname"]
        grouped_profiles[group_name] ||= []
        grouped_profiles[group_name] << {
          attribute: row["attribute"],
          op: row["op"],
          value: row["value"]
        }
      end
      grouped_profiles
    rescue StandardError => e
      Rails.logger.error "Failed to fetch all RADIUS profiles: #{e.message}"
      {} # Return empty hash on error
    end

    def self.find_profile(group_name)
      sql = <<-SQL
        SELECT groupname, attribute, op, value
        FROM radgroupreply
        WHERE groupname = ?
        ORDER BY attribute
      SQL

      results = ActiveRecord::Base.connection.select_all(
        ActiveRecord::Base.send(:sanitize_sql_array, [ sql, group_name ])
      )

      if results.empty?
        nil # Not found
      else
        # Process into a single profile hash for consistent output
        profile_data = {
          group_name: results.first["groupname"],
          attributes: []
        }
        results.each do |row|
          profile_data[:attributes] << {
            attribute: row["attribute"],
            op: row["op"],
            value: row["value"]
          }
        end
        profile_data
      end
    rescue StandardError => e
      Rails.logger.error "Failed to find RADIUS profile '#{group_name}': #{e.message}"
      nil
    end

    # this is the code to delete radius subscription profiles

    def self.delete_profile(group_name)
      delete_sql = <<-SQL
          DELETE FROM radgroupreply
          WHERE groupname = ?
        SQL
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.send(:sanitize_sql_array, [ delete_sql, group_name ])
      )
    rescue StandardError => e
      Rails.logger.error "Failed to find RADIUS profile '#{group_name}': #{e.message}"
      nil
    end

    # Now the code to search if radius profile exist

    def self.group_name_exists?(group_name)
      sql = <<-SQL
        SELECT EXISTS (
          SELECT 1 FROM radgroupreply WHERE groupname = ? LIMIT 1
        ) AS exists_check
      SQL
      result = ActiveRecord::Base.connection.select_one(
        ActiveRecord::Base.send(:sanitize_sql_array, [ sql, group_name ])
      )
      result["exists_check"] # Returns true or false
    rescue StandardError => e
      Rails.logger.error "Error checking FreeRADIUS group name existence: #{e.message}"
      false # Assume it doesn't exist on error
    end
  end
end
