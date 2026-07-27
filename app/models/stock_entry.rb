class StockEntry < ApplicationRecord
  belongs_to :spare_part
  belongs_to :warehouse
end
