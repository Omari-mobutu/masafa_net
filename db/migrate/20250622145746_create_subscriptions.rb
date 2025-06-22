class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :name, null: false, index: { unique: true } # e.g., "Basic 6Mbps", "Premium 20Mbps"
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false # For Kenya Shillings, adjust precision/scale if needed
      t.integer :duration_minutes, null: false # e.g., 60 for 1 hour, 1440 for 24 hours
      t.string :freeradius_group_name, null: false, index: true # This links to your radgroupreply.groupname

      t.timestamps
    end
  end
end
