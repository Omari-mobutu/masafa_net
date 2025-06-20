class RadprofileController < ApplicationController
  def index
    @profiles = CreateProfile.all_profiles
  end
  def new
  end

  def show
  end

  def create
    profile_data = radprofile_params

    if CreateProfile.new(profile_data).create_radius_profile
      flash[:notice] = "RADIUS profile created successfully!"
      redirect_to root_path # Or wherever you list profiles
    else
      flash.now[:alert] = "Failed to create RADIUS profile."
      render :new, status: :unprocessable_entity
    end
  end

  private
  def radprofile_params
    params.require(:radprofile).permit(
      :group_name,
      :rate_limit,
      :session_timeout,
      :idle_timeout # Add other predefined attributes here
    )
  end
end
