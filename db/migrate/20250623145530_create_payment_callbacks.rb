class CreatePaymentCallbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_callbacks do |t|
      t.jsonb :data
      t.string :status, null: false, default: 'pending' # pending, successful, failed, cancelled

      t.timestamps
    end
  end
end
