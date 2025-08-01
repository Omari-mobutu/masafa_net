class AddCredentialsToGiftedSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :gifted_subscriptions, :username, :string
    add_column :gifted_subscriptions, :password, :string
  end
end
