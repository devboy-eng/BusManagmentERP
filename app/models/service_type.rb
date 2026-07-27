class ServiceType < ApplicationRecord
  has_many :job_cards

  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(sort_order: :asc, name: :asc) }
end
