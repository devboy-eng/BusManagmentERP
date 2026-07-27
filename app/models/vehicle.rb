class Vehicle < ApplicationRecord
  belongs_to :customer
  has_many :job_cards, dependent: :destroy
  has_many :service_reminders, dependent: :destroy

  enum status: { active: 0, inactive: 1, scrapped: 2 }

  validates :registration_number, presence: true, uniqueness: true
  validates :make, presence: true
  validates :customer_id, presence: true

  scope :active_vehicles, -> { where(status: :active) }

  def display_name
    "#{registration_number} - #{make} #{model}"
  end

  def documents_expiring_soon?(days = 30)
    threshold = Date.current + days.days
    (insurance_expiry_date.present? && insurance_expiry_date <= threshold) ||
    (fitness_certificate_expiry.present? && fitness_certificate_expiry <= threshold) ||
    (puc_expiry_date.present? && puc_expiry_date <= threshold)
  end
end
