class AddPostAuthStatusToPaymentTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_transactions, :post_auth_status, :string, default: 'pending_auth', null: false
    add_column :payment_transactions, :authenticated_at, :datetime
    add_column :payment_transactions, :expected_stop_time, :datetime
    # Add indexes for efficient querying
    add_index :payment_transactions, :post_auth_status
    add_index :payment_transactions, :expected_stop_time
  end
end
