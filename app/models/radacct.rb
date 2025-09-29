# Example read-only model
class Radacct < ApplicationRecord
  self.table_name = "radacct"
  self.primary_key = "radacctid"
  # Prevent accidental writes
  def readonly?
    true
  end
end
