# app/services/rad_profile/get_auth_status.rb
module Radprofile
  class GetAuthStatus
    def self.call(username:)
      # Find the latest authentication attempt for the given username
      query = <<-SQL
        SELECT
            username,
            reply,
            authdate,
            calledstationid,
            callingstationid
        FROM
            radpostauth
        WHERE
            username = $1
        ORDER BY
            authdate DESC
        LIMIT 1;
      SQL

      begin
        result = ActiveRecord::Base.connection.exec_query(query, "SQL", [ username ]).first

        if result
          {
            username: result["username"],
            status: (result["reply"] == "Access-Accept" ? "success" : "failure"),
            raw_reply: result["reply"], # For debugging, if needed
            auth_at: result["authdate"],
            called_station_id: result["calledstationid"],
            calling_station_id: result["callingstationid"]
          }
        else
          nil # No authentication attempts found for this user
        end
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "SQL error retrieving auth status for #{username}: #{e.message}"
        nil
      rescue StandardError => e
        Rails.logger.error "Error retrieving auth status for #{username}: #{e.message}"
        nil
      end
    end
  end
end
