class CreateGiftedSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :gifted_subscriptions do |t|
      t.string :mac_address
      t.string :package_name
      t.datetime :redeemed_at

      t.timestamps
    end
  end
end
