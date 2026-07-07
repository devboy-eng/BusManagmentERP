class FollowUp < ApplicationRecord
  belongs_to :lead
  belongs_to :user, optional: true

  enum :status, { pending: 0, sent: 1, failed: 2, cancelled: 3 }, default: :pending

  validates :message, presence: true
  validates :scheduled_at, presence: true
  validate :scheduled_at_must_be_in_future, on: :create

  scope :due, -> { pending.where("scheduled_at <= ?", Time.current) }
  scope :upcoming, -> { pending.where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :ordered, -> { order(scheduled_at: :desc) }

  private

  def scheduled_at_must_be_in_future
    return if scheduled_at.blank?

    if scheduled_at <= Time.current
      errors.add(:scheduled_at, "must be in the future")
    end
  end
end
