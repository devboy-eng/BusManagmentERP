class JobCard < ApplicationRecord
  belongs_to :vehicle
  belongs_to :customer
  belongs_to :branch
  belongs_to :service_advisor, class_name: "User"
  belongs_to :service_type, optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :gate_pass_issued_by, class_name: "User", optional: true

  has_many :inspections, dependent: :destroy
  has_many :estimates, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :technician_assignments, dependent: :destroy
  has_many :technicians, through: :technician_assignments
  has_many :comments, as: :commentable, dependent: :destroy

  enum status: {
    checked_in: 0, inspection_done: 1, estimate_created: 2, estimate_sent: 3,
    customer_approved: 4, manager_approved: 5, in_progress: 6,
    additional_work_requested: 7, completed: 8, invoiced: 9, paid: 10,
    gate_pass_issued: 11, cancelled: 12
  }

  enum priority: { normal: 0, urgent: 1, critical: 2 }

  validates :vehicle_id, presence: true
  validates :customer_id, presence: true
  validates :branch_id, presence: true

  before_create :generate_job_card_number
  before_create :generate_approval_tokens

  scope :active, -> { where.not(status: [:gate_pass_issued, :cancelled]) }
  scope :today, -> { where("checked_in_at >= ?", Date.current.beginning_of_day) }
  scope :by_branch, ->(branch_id) { where(branch_id: branch_id) }

  def turnaround_hours
    return nil unless gate_pass_issued_at && checked_in_at
    ((gate_pass_issued_at - checked_in_at) / 1.hour).round(1)
  end

  private

  def generate_job_card_number
    year = Date.current.year
    last = JobCard.where("job_card_number LIKE ?", "JC-#{year}-%").order(:job_card_number).last
    next_num = last ? last.job_card_number.split("-").last.to_i + 1 : 1
    self.job_card_number = "JC-#{year}-#{next_num.to_s.rjust(4, '0')}"
  end

  def generate_approval_tokens
    self.customer_approval_token ||= SecureRandom.urlsafe_base64(32)
    self.manager_approval_token ||= SecureRandom.urlsafe_base64(32)
  end
end
