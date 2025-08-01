class AddMpesaResultToPaymentTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_transactions, :mpesa_result_code, :integer
    add_column :payment_transactions, :mpesa_result_desc, :string
  end
end
