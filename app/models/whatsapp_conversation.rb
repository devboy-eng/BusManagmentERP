class WhatsappConversation < ApplicationRecord
  belongs_to :contact, polymorphic: true, optional: true
  has_many :whatsapp_messages, dependent: :nullify

  validates :contact_phone, presence: true, uniqueness: true

  scope :ordered, -> { order(last_message_at: :desc) }
  scope :with_unread, -> { where("unread_count > 0") }

  def self.find_or_start(phone:, name: nil, contact: nil)
    normalized = WhatsappService.normalize_phone(phone)
    conversation = find_by_phone(normalized) || new(contact_phone: normalized)

    if conversation.new_record?
      conversation.contact_name = name
      if contact
        conversation.contact = contact
      else
        conversation.contact = find_contact_by_phone(normalized)
      end
      conversation.contact_name ||= conversation.contact&.name
      conversation.save!
    elsif contact && conversation.contact.nil?
      conversation.update!(contact: contact, contact_name: name || contact.name)
    end

    conversation
  end

  # Find conversation by phone, handling multiple formats (+91xxx, 91xxx, xxx)
  def self.find_by_phone(normalized_digits)
    find_by(contact_phone: normalized_digits) ||
      find_by(contact_phone: "+#{normalized_digits}") ||
      (normalized_digits.length > 10 ? find_by(contact_phone: normalized_digits.last(10)) : nil)
  end

  def mark_as_read!
    update!(unread_count: 0)
  end

  def increment_unread!
    increment!(:unread_count)
  end

  def update_last_message!(message)
    update!(
      last_message_body: message.message_body,
      last_message_at: message.created_at
    )
  end

  def display_name
    contact_name.presence || contact&.name.presence || contact_phone
  end

  def last_message_preview
    return "" if last_message_body.blank?
    last_message_body.truncate(50)
  end

  # Meta allows free-form replies only within 24 hours of the customer's last message.
  # Outside this window, only approved template messages can be sent.
  def within_reply_window?
    last_incoming = whatsapp_messages.incoming.order(created_at: :desc).first
    return false unless last_incoming
    last_incoming.created_at > 24.hours.ago
  end

  private

  def self.find_contact_by_phone(phone)
    digits = phone.gsub(/\D/, "")
    # Try exact match first, then last 10 digits
    last_ten = digits.last(10)

    Customer.find_by(phone: phone) ||
      Customer.find_by(phone: last_ten) ||
      Customer.find_by(phone: "91#{last_ten}") ||
      Customer.find_by(phone: "+91#{last_ten}") ||
      Lead.find_by(phone: phone) ||
      Lead.find_by(phone: last_ten) ||
      Lead.find_by(phone: "91#{last_ten}") ||
      Lead.find_by(phone: "+91#{last_ten}")
  end
end
