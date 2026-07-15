class WhatsappMessage < ApplicationRecord
  belongs_to :recipient, polymorphic: true, optional: true
  belongs_to :user, optional: true
  belongs_to :whatsapp_conversation, optional: true

  enum :status, { queued: 0, sent: 1, delivered: 2, read: 3, failed: 4 }, default: :queued

  validates :recipient_phone, presence: true
  validates :message_body, presence: true, unless: :media_or_reaction?

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :incoming, -> { where(direction: "incoming") }
  scope :outgoing, -> { where(direction: "outgoing") }
  scope :search_content, ->(query) { where("message_body LIKE ?", "%#{query}%") }

  def incoming?
    direction == "incoming"
  end

  def outgoing?
    direction != "incoming"
  end

  def media?
    message_type.in?(%w[image video audio document])
  end

  def image?
    message_type == "image"
  end

  def video?
    message_type == "video"
  end

  def audio?
    message_type == "audio"
  end

  def document?
    message_type == "document"
  end

  def reaction?
    message_type == "reaction"
  end

  def button_reply?
    message_type == "button_reply"
  end

  private

  def media_or_reaction?
    media? || reaction?
  end
end
