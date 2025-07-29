class ClientSessionsController < ApplicationController
  def index
    # Initial load of all active sessions for the main page view
    @active_sessions = Radprofile::GetActiveSession.call
  end
  def refresh
    # This action is called by the Turbo Frame to get updated data
    @active_sessions = Radprofile::GetActiveSession.call

    # Render a Turbo Stream. This will update the turbo_frame_tag with id "active_sessions_table"
    respond_to do |format|
      format.turbo_stream do
        # Rails will look for app/views/client_sessions/refresh.turbo_stream.erb
        # and render it with the correct content-type.
        render
      end
      # If the request's Accept header doesn't include turbo_stream,
      # respond with a 406 Not Acceptable error.
      # This confirms that no other format is being accidentally hit.
      format.any { head :not_acceptable }
    end
  end
end
