class PaymentsController < ApplicationController
  # before_action :authenticate_user!, only: %i[index show destroy]
  # before_action :check_if_admin, only: %i[index show destroy]
  allow_unauthenticated_access
  before_action :set_payment, only: %i[show destroy]
  skip_forgery_protection only: [ :create ]

  # GET /payments or /payments.json
  def index
    @payments = PaymentCallback.all
  end

  # GET /payments/1 or /payments/1.json
  def show
  end

  # POST /payments or /payments.json
  def create
    @payment = PaymentCallback.new(data: payload, status: :pending)

    if @payment.save
      PaymentJob.perform_later(@payment)
      render json: { status: :ok }, status: :ok
    else
      render json: { errors: :payment.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /payments/1 or /payments/1.json
  def destroy
    @payment.destroy!

    respond_to do |format|
      format.html { redirect_to payments_url, notice: "Payment was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_payment
    @payment = PaymentCallback.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def payment_params
    params.require(:payment).permit(:data, :status)
  end

  def payload
    @payload ||= request.body.read
  end
end
