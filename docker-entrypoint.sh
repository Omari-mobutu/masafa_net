#!/bin/sh
set -e

# List of FreeRADIUS config files that need environment variable substitution
# Add any other files where you use ${ENV_VAR} syntax
CONFIG_FILES_TO_TEMPLATE=(
    "/etc/freeradius/mods-enabled/sql"
    "/etc/freeradius/clients.conf"
    "/etc/freeradius/sites-enabled/default" # Only if you put ENV vars in here
)

echo "Templating FreeRADIUS configuration files with environment variables..."
for config_file in "${CONFIG_FILES_TO_TEMPLATE[@]}"; do
    if [ -f "$config_file" ]; then
        echo "Processing: $config_file"
        # Use envsubst to replace variables and overwrite the file
        envsubst < "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    else
        echo "Warning: Config file not found - $config_file"
    fi
done

# Execute the main FreeRADIUS command passed as CMD
echo "Starting FreeRADIUS..."
exec "$@"