class UpdatePaymentTransactionPostAuthStatusJob < ApplicationJob
  queue_as :default # Or a specific queue for long-running tasks

  def perform(payment_transaction_id)
    transaction = PaymentTransaction.find_by(id: payment_transaction_id)
    return unless transaction && transaction.username.present?

    Rails.logger.info "Processing post status for PaymentTransaction ##{transaction.id} (User: #{transaction.username})"

    # 1. Get Authentication Status from radpostauth
    auth_status = Radprofile::GetAuthStatus.call(username: transaction.username)

    if auth_status
      transaction.update!(
        post_auth_status: auth_status[:status],
       authenticated_at: auth_status[:auth_at]
      )
      Rails.logger.info "Updated auth status for #{transaction.username}: #{auth_status[:status]}"
    else
      # No auth record found yet, keep 'pending_auth' or set a specific status
      Rails.logger.info "No auth record found for #{transaction.username}. Status remains 'pending_auth'."
    end

    # 2. Calculate and Set Expected Stop Time (Based on subscription plan)
    # This logic assumes your PaymentTransaction might have a link to a subscription plan
    # or a 'duration_in_hours' attribute, etc.
    if transaction.expected_stop_time.blank? && transaction.successful? # Only set if not already set and payment successful
      subscription_duration_minutes = Subscription.find(transaction.subscription_id).duration_minutes# Example: 60 minutes. Get this from your actual plan/product
      # If your transaction stores the plan/product, you'd fetch duration like:
      # subscription_duration_minutes = transaction.product.duration_in_minutes
      transaction.update!(expected_stop_time: Time.current + subscription_duration_minutes.minutes)
      Rails.logger.info "Set expected stop time for #{transaction.username} to #{transaction.expected_stop_time}"
    end


    # This job can be made idempotent by checking current state before attempting updates.
    # For example, if hotspot_auth_status is already 'session_active', you might skip some steps.
    # This simple version will update at each run.
  rescue StandardError => e
    Rails.logger.error "Error updating post auth status for PaymentTransaction ##{transaction.id}: #{e.message}"
    # Optionally, re-raise to retry, or notify error tracking
    raise e
  end
end
