# freeradius.Dockerfile
# Use an official FreeRADIUS base image
# Alpine is often preferred for smaller image size. Choose a version that matches your dev.
FROM freeradius/freeradius-server:3.0.26-alpine

# Install gettext-runtime for envsubst utility (needed for templating config files)
RUN apk add --no-cache gettext

# Remove default configurations to avoid conflicts
RUN rm -rf /etc/freeradius/*

# Copy your custom FreeRADIUS configuration files into the container
# This copies everything from your freeradius_config/ directory
COPY freeradius_config/ /etc/freeradius/

# Ensure necessary permissions
RUN chown -R freeradius:freeradius /etc/freeradius
RUN chmod -R go-w /etc/freeradius

# Ensure the 'sql' module is symlinked correctly if it's not by default
# This step might vary depending on how you structure mods-enabled in your copy
#RUN ln -sf /etc/freeradius/mods-available/sql /etc/freeradius/mods-enabled/sql || true # Using || true to prevent build failure if symlink already exists or path is different

# Set the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]


# Expose standard RADIUS ports (UDP)
EXPOSE 1812/udp
EXPOSE 1813/udp

# Default command to run FreeRADIUS in foreground
# This will be executed by the entrypoint script
#CMD ["radiusd", "-f"] # -f for foreground, keep debugging on for now
CMD ["/usr/sbin/freeradius", "-f", "-XX"]
# -f for foreground, -XX for extra debug (remove in prod)