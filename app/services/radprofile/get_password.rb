# app/services/rad_profile/get_password.rb
module Radprofile
  class GetPassword
    def initialize(username)
      @username = username
    end

    # Call method to execute the service logic
    def call
      # IMPORTANT: Use parameterized queries to prevent SQL injection.
      # ActiveRecord::Base.connection.quote will properly escape the username.
      escaped_username = ActiveRecord::Base.connection.quote(@username)

      # Construct the SQL query.
      # We are looking for the 'Cleartext-Password' attribute with 'op' as ':='
      sql_query = <<-SQL
        SELECT value
        FROM radcheck
        WHERE username = #{escaped_username}
          AND attribute = 'Cleartext-Password'
          AND op = ':='
        LIMIT 1;
      SQL

      begin
        # Execute the query and get the single value (the password)
        password = ActiveRecord::Base.connection.select_value(sql_query)
        password # Returns the password string or nil if not found
      rescue ActiveRecord::StatementInvalid => e
        # Handle SQL query errors
        Rails.logger.error "SQL error retrieving password for #{@username} from radcheck: #{e.message}"
        nil
      rescue StandardError => e
        # Catch any other unexpected errors
        Rails.logger.error "Error retrieving password for #{@username} from radcheck: #{e.message}"
        nil
      end
    end
  end
end
