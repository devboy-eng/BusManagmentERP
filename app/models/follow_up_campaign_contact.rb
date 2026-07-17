class FollowUpCampaignContact < ApplicationRecord
  belongs_to :follow_up_campaign
  belongs_to :lead, optional: true
  belongs_to :customer, optional: true

  enum :status, { queued: 0, accepted: 1, sent: 2, delivered: 3, read: 4, failed: 5, expired: 6 }, default: :queued

  validates :phone, presence: true

  scope :by_status, ->(status) { where(status: status) }
end
