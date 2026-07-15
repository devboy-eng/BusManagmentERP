class AutoReplyRule < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :reply_body, presence: true
  validates :keyword, presence: true, if: -> { trigger_type == "keyword" }

  scope :active, -> { where(active: true) }
  scope :keyword_rules, -> { where(trigger_type: "keyword") }
  scope :first_message_rules, -> { where(trigger_type: "first_message") }
  scope :outside_hours_rules, -> { where(trigger_type: "outside_hours") }

  TRIGGER_TYPES = %w[keyword first_message outside_hours].freeze

  def self.match_incoming(text, conversation)
    # Check keyword rules first
    keyword_rules.active.find_each do |rule|
      return rule if text.to_s.downcase.include?(rule.keyword.downcase)
    end

    # Check first_message rules (no previous outgoing messages in conversation)
    if conversation.whatsapp_messages.outgoing.count.zero?
      rule = first_message_rules.active.first
      return rule if rule
    end

    # Check outside_hours rules (outside 9 AM - 6 PM)
    now = Time.current
    if now.hour < 9 || now.hour >= 18
      rule = outside_hours_rules.active.first
      return rule if rule
    end

    nil
  end
end
