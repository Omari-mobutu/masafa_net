class Subscription < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :freeradius_group_name, presence: true

  # Optional: A custom validation to check if the freeradius_group_name actually exists
  # in your radgroupreply table. This would query the FreeRADIUS DB.
  validate :freeradius_group_name_exists

  private

  def freeradius_group_name_exists
    # This requires querying the FreeRADIUS database directly
    # You could add a method to your RadprofileService for this:
    # `RadprofileService.group_name_exists?(freeradius_group_name)`
    # This check ensures data integrity between your Rails app and FreeRADIUS DB.
    # For simplicity, you might skip this for now and rely on manual matching,
    # but for production, it's good practice.
    unless Radprofile::GetProfiles.group_name_exists?(freeradius_group_name)
      errors.add(:freeradius_group_name, "must correspond to an existing FreeRADIUS profile group name.")
    end
  end
end
