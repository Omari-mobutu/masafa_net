# Example read-only model
class Radacct < ApplicationRecord
  self.table_name = "radacct"
  self.primary_key = "radacctid"

  # Alias the problematic 'class' column to a safe name like 'session_class'
  alias_attribute :session_class, :class
  # Prevent accidental writes
  def readonly?
    true
  end
end
