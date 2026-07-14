class CsatResponse < ApplicationRecord
  belongs_to :respondent, polymorphic: true, optional: true
  belongs_to :user, optional: true

  before_create :generate_token

  # Validations only on submit context (not when generating link)
  validates :service_rating, presence: true, inclusion: { in: 1..5 }, on: :submit
  validates :support_rating, presence: true, inclusion: { in: 1..5 }, on: :submit
  validates :would_recommend, inclusion: { in: [true, false] }, on: :submit

  scope :submitted, -> { where.not(submitted_at: nil) }
  scope :pending, -> { where(submitted_at: nil) }
  scope :recent, -> { submitted.order(submitted_at: :desc) }

  def submitted?
    submitted_at.present?
  end

  # --- Analytics Class Methods ---

  def self.average_service_rating
    submitted.average(:service_rating)&.round(1) || 0
  end

  def self.average_support_rating
    submitted.average(:support_rating)&.round(1) || 0
  end

  def self.recommendation_rate
    total = submitted.count
    return 0 if total.zero?
    (submitted.where(would_recommend: true).count.to_f / total * 100).round(1)
  end

  def self.overall_csat_score
    avg_service = submitted.average(:service_rating) || 0
    avg_support = submitted.average(:support_rating) || 0
    return 0 if avg_service.zero? && avg_support.zero?
    ((avg_service + avg_support) / 2.0).round(1)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(24)
  end
end
