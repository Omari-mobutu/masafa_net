# app/services/rad_profile/get_active_session.rb
module Radprofile
  class GetActiveSession
    def self.call(username: nil)
      query = "SELECT  username, acctstarttime, nasipaddress, callingstationid, acctsessionid, acctinputoctets, acctoutputoctets FROM radacct WHERE acctstoptime IS NULL"
      params = []

      if username.present?
        query += " AND username = $1"
        params << username
      end

      # Use ActiveRecord's connection for raw SQL queries
      # Make sure your database connection details are correctly configured for PostgreSQL
      results = ActiveRecord::Base.connection.exec_query(query, "SQL", params)

      # Map the results to a more convenient format (e.g., array of hashes or custom objects)
      results.map do |row|
        {

          username: row["username"],
          acct_start_time: row["acctstarttime"],
          nas_ip_address: row["nasipaddress"],
          calling_station_id: row["callingstationid"],
          acct_session_id: row["acctsessionid"],
          acct_input_octets: row["acctinputoctets"],
          acct_output_octets: row["acctoutputoctets"]
        }
      end
    end
  end
end
