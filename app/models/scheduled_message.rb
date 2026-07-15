class ScheduledMessage < ApplicationRecord
  belongs_to :whatsapp_conversation
  belongs_to :user, optional: true

  enum :status, { pending: 0, sent: 1, failed: 2, cancelled: 3 }

  validates :message_body, presence: true
  validates :scheduled_at, presence: true
  validate :scheduled_at_in_future, on: :create

  scope :due, -> { pending.where("scheduled_at <= ?", Time.current) }
  scope :upcoming, -> { pending.where("scheduled_at > ?", Time.current) }

  private

  def scheduled_at_in_future
    return if scheduled_at.blank?
    errors.add(:scheduled_at, "must be in the future") if scheduled_at <= Time.current
  end
end
