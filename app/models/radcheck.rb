class Radcheck < ApplicationRecord
  self.table_name = "radcheck"
  alias_attribute :att, :attribute
end
