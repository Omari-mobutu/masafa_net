class CreatePaymentTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_transactions do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :phone_number, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :client_mac, null: false
      t.string :client_ip, null: false
      t.string :link_login, null: false # Store this for the final redirect

      # M-Pesa specific fields
      t.string :mpesa_checkout_request_id, index: { unique: true } # Important for linking callback
      t.string :mpesa_merchant_request_id
      t.string :status, null: false, default: 'pending' # pending, successful, failed, cancelled
      t.jsonb :payment_details, default: {} # Store full M-Pesa callback payload

      # Fields for the generated RADIUS user
      t.string :username
      t.string :password_digest # Store a hashed version of the RADIUS password
      t.string :subscription_name

      t.timestamps
    end
  end
end
