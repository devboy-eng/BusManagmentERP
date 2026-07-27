class TechnicianAssignment < ApplicationRecord
  belongs_to :job_card
  belongs_to :technician

  enum status: { assigned: 0, in_progress: 1, completed: 2 }
end
