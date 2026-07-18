class FollowUpCampaign < ApplicationRecord
  belongs_to :whatsapp_template
  belongs_to :user, optional: true
  has_many :contacts, class_name: "FollowUpCampaignContact", dependent: :destroy

  enum :status, { pending: 0, processing: 1, completed: 2, cancelled: 3 }, default: :pending

  validates :whatsapp_template, presence: true
  validates :scheduled_at, presence: true
  validate :scheduled_at_must_be_in_future, on: :create

  scope :ordered, -> { order(scheduled_at: :desc) }
  scope :due, -> { pending.where("scheduled_at <= ?", Time.current) }

  def parsed_template_variables
    return [] if template_variables.blank?
    JSON.parse(template_variables) rescue []
  end

  def update_counts!
    update!(
      total_contacts: contacts.count,
      sent_count: contacts.where(status: [:sent, :delivered, :read]).count,
      delivered_count: contacts.where(status: [:delivered, :read]).count,
      read_count: contacts.where(status: :read).count,
      failed_count: contacts.where(status: :failed).count,
      expired_count: contacts.where(status: :expired).count
    )
  end

  def analytics
    total = total_contacts.to_i
    return {} if total.zero?

    queued_count = Rails.cache.fetch("campaign/#{id}/queued_count", expires_in: 2.minutes) { contacts.where(status: :queued).count }
    accepted_count = Rails.cache.fetch("campaign/#{id}/accepted_count", expires_in: 2.minutes) { contacts.where(status: :accepted).count }

    {
      total_contacts: total,
      delivered: { count: delivered_count, pct: (delivered_count * 100.0 / total).round(1) },
      read: { count: read_count, pct: (read_count * 100.0 / total).round(1) },
      failed: { count: failed_count, pct: (failed_count * 100.0 / total).round(1) },
      expired: { count: expired_count, pct: (expired_count * 100.0 / total).round(1) },
      sent: { count: sent_count, pct: (sent_count * 100.0 / total).round(1) },
      queued: { count: queued_count, pct: (queued_count * 100.0 / total).round(1) },
      accepted: { count: accepted_count, pct: (accepted_count * 100.0 / total).round(1) }
    }
  end

  private

  def scheduled_at_must_be_in_future
    return if scheduled_at.blank?

    if scheduled_at <= Time.current
      errors.add(:scheduled_at, "must be in the future")
    end
  end
end
