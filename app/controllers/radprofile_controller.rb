class RadprofileController < ApplicationController
  before_action :set_profile, only: %i[show edit update destroy]
  def index
    @profiles = Radprofile::GetProfiles.all_profiles
  end
  def new
  end

  def show
  end
  def edit
  end

  def create
    profile_data = radprofile_params

    if Radprofile::CreateProfile.call(profile_data)
      flash[:notice] = "RADIUS profile created successfully!"
      redirect_to root_path # Or wherever you list profiles
    else
      flash.now[:alert] = "Failed to create RADIUS profile."
      render :new, status: :unprocessable_entity
    end
  end

  def update
    profile_data = radprofile_params

    if Radprofile::UpdateProfile.call(profile_data)
      flash[:notice] = "RADIUS profile successfully updated!"
      redirect_to radprofile_path(@profile[:group_name]) # Or wherever you list profiles
    else
      flash.now[:alert] = "Failed to update the RADIUS profile."
      render :new, status: :unprocessable_entity
    end
  end
  def destroy
    @profile = Radprofile::GetProfiles.delete_profile(params[:group_name])
    if @profile
      flash[:alert] = "RADIUS profile successfully destroyed!"
      redirect_to radprofile_index_path
    else
      flash[:alert] = "RADIUS profile not found."
      redirect_to radprofile_index_path
    end
  end

  private
  def set_profile
    @profile = Radprofile::GetProfiles.find_profile(params[:group_name]) # params[:id] will be the groupname
    unless @profile
      flash[:alert] = "RADIUS profile not found."
      redirect_to radprofile_index_path
    end
  end
  def radprofile_params
    params.require(:radprofile).permit(
      :group_name,
      :rate_limit,
      :session_timeout,
      :idle_timeout # Add other predefined attributes here
    )
  end
end
