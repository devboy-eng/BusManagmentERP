class Inspection < ApplicationRecord
  belongs_to :job_card
  belongs_to :inspected_by, class_name: "User"
  has_many :inspection_items, dependent: :destroy

  accepts_nested_attributes_for :inspection_items, allow_destroy: true, reject_if: :all_blank

  enum overall_condition: { good: 0, fair: 1, needs_attention: 2, critical: 3 }
end
