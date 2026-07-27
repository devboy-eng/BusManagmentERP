class Technician < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :branch, optional: true
  has_many :technician_assignments, dependent: :destroy
  has_many :job_cards, through: :technician_assignments

  enum status: { active: 0, inactive: 1 }

  validates :name, presence: true
  validates :employee_id, uniqueness: true, allow_blank: true

  scope :active_technicians, -> { where(status: :active) }
  scope :by_branch, ->(branch_id) { where(branch_id: branch_id) }
end
