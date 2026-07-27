class ServiceReminder < ApplicationRecord
  belongs_to :vehicle
  belongs_to :customer
  belongs_to :created_by, class_name: "User", optional: true

  enum status: { pending: 0, sent: 1, acknowledged: 2, completed: 3 }

  REMINDER_TYPES = %w[next_service insurance fitness puc permit].freeze

  validates :reminder_type, presence: true
  validates :due_date, presence: true

  scope :due_soon, -> { where("due_date <= ?", 7.days.from_now).pending }
  scope :overdue, -> { where("due_date < ?", Date.current).pending }
end
