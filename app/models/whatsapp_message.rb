class WhatsappMessage < ApplicationRecord
  belongs_to :recipient, polymorphic: true, optional: true
  belongs_to :user, optional: true
  belongs_to :whatsapp_conversation, optional: true

  enum :status, { queued: 0, sent: 1, delivered: 2, read: 3, failed: 4 }, default: :queued

  validates :recipient_phone, presence: true
  validates :message_body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :incoming, -> { where(direction: "incoming") }
  scope :outgoing, -> { where(direction: "outgoing") }

  def incoming?
    direction == "incoming"
  end

  def outgoing?
    direction != "incoming"
  end
end
