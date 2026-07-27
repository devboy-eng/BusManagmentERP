class InspectionItem < ApplicationRecord
  belongs_to :inspection

  enum condition: { good: 0, fair: 1, needs_attention: 2, critical: 3 }

  validates :area, presence: true

  AREAS = %w[Engine Brakes Electrical Body AC Tyres Suspension Steering Transmission Exhaust Lights Interior Wipers Battery Coolant].freeze
end
