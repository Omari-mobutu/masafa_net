# app/services/radprofile/create_user.rb
module Radprofile
  class CreateUser < ApplicationService
    def initialize(username, password, group_name)
      @username = username
      @password = password # Plain text password to be hashed before storing
      @group_name = group_name
    end

    def call
      create_radius_user
    end

    private

    def create_radius_user
      return false unless @username.present? && @password.present? && @group_name.present?

      # Hash the password for storage in radcheck
      # Ensure this matches what FreeRADIUS expects (e.g., {crypt}, {md5}, or plain for PAP)
      # For {crypt}, you'd need the 'bcrypt' gem:
      # gem 'bcrypt', '~> 3.10'
      # hashed_password = "{crypt}" + BCrypt::Password.create(@password)

      # For plain PAP (less secure but common for simple setups):
      hashed_password = @password # If FreeRADIUS directly checks plain passwords via 'User-Password == "plain_password"'

      ActiveRecord::Base.connection.transaction do
        # 1. Insert into radcheck (username and password)
        sql_radcheck = <<-SQL
          INSERT INTO radcheck (username, attribute, op, value)
          VALUES (?, 'User-Password', ':=', ?)
        SQL
        # Using '!=' for op and value for password (with Auth-Type := Local) allows FreeRADIUS
        # to store hashed passwords using {crypt} or {md5} and verify them.
        # If your FreeRADIUS setup is very basic and uses 'Auth-Type := PAP', 'User-Password == "plain_password"',
        # then '==' and the plain password might be used.
        # ':=' is more flexible, assuming FreeRADIUS is configured to handle `User-Password` properly.

        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.send(:sanitize_sql_array, [ sql_radcheck, @username, hashed_password ])
        )

        # 2. Insert into radusergroup (link user to profile group)
        sql_radusergroup = <<-SQL
          INSERT INTO radusergroup (username, groupname, priority)
          VALUES (?, ?, 1)
        SQL
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.send(:sanitize_sql_array, [ sql_radusergroup, @username, @group_name ])
        )
      end

      Rails.logger.info "Successfully created RADIUS user '#{@username}' with group '#{@group_name}'."
      true
    rescue StandardError => e
      Rails.logger.error "Failed to create RADIUS user '#{@username}': #{e.message}"
      false
    end
  end
end
