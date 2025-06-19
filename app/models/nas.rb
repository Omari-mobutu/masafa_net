class Nas < ApplicationRecord
  self.table_name = "nas"
  self.inheritance_column = :not_type
end
