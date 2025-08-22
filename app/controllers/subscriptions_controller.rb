class SubscriptionsController < ApplicationController
before_action :set_subscription, only: %i[ show edit update destroy ]

  # GET /subscriptions
  # Displays a list of all subscriptions.
  def index
    @subscriptions = Subscription.all
  end

  # GET /subscriptions/1
  # Displays details for a single subscription.
  def show
  end

  # GET /subscriptions/new
  # Displays the form for creating a new subscription.
  def new
    @subscription = Subscription.new
    @profiles = Radprofile::GetProfiles.all_profiles
  end

  # GET /subscriptions/1/edit
  # Displays the form for editing an existing subscription.
  def edit
    @profiles = Radprofile::GetProfiles.all_profiles
  end

  # POST /subscriptions
  # Creates a new subscription with submitted form data.
  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      redirect_to @subscription, notice: "Subscription was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /subscriptions/1
  # Updates an existing subscription with submitted form data.
  def update
    if @subscription.update(subscription_params)
      redirect_to @subscription, notice: "Subscription was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /subscriptions/1
  # Deletes a subscription.
  def destroy
    @subscription.destroy!
    redirect_to subscriptions_url, notice: "Subscription was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscription_params
      params.require(:subscription).permit(:name, :description, :price, :duration_minutes, :freeradius_group_name)
    end
end
