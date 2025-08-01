# app/jobs/update_gift_redemption_job.rb
class UpdateGiftRedemptionJob < ApplicationJob
  queue_as :default # You can configure different queues if needed

  def perform(gift_subscription_id)
    gift = GiftedSubscription.find_by(id: gift_subscription_id)
    if gift && gift.redeemed_at.nil?
      # Update the redeemed_at timestamp to the current time
      gift.update(redeemed_at: Time.current)
      Rails.logger.info "GiftedSubscription #{gift_subscription_id} redemption time updated in background."
    elsif gift && gift.redeemed_at.present?
      Rails.logger.warn "GiftedSubscription #{gift_subscription_id} already redeemed. No update performed."
    else
      Rails.logger.error "GiftedSubscription with ID #{gift_subscription_id} not found for redemption update."
    end
  end
end
