class WhatsappMenu < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :body_text, presence: true
  validates :button_text, presence: true, length: { maximum: 20 }
  validates :header_text, length: { maximum: 60 }, allow_blank: true
  validates :footer_text, length: { maximum: 60 }, allow_blank: true
  validate :validate_menu_items

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(created_at: :desc) }

  def parsed_menu_items
    return [] if menu_items.blank?
    JSON.parse(menu_items) rescue []
  end

  def parsed_menu_items=(items)
    self.menu_items = items.to_json
  end

  # Parse comma-separated trigger keywords into an array
  def trigger_keywords
    return [] if trigger_keyword.blank?
    trigger_keyword.split(",").map(&:strip).reject(&:blank?)
  end

  # Find active menu by matching any of its trigger keywords
  def self.find_by_trigger(text)
    normalized = text.to_s.downcase.strip
    return nil if normalized.blank?

    active.where.not(trigger_keyword: [nil, ""]).find_each do |menu|
      menu.trigger_keywords.each do |kw|
        return menu if normalized == kw.downcase
      end
    end
    nil
  end

  # Find the reply text for a selected menu item
  def reply_for_item(item_id)
    parsed_menu_items.find { |item| item["id"] == item_id }&.dig("reply_text")
  end

  # Build the sections payload for WhatsApp API
  def api_sections
    items = parsed_menu_items
    [{
      title: "Options",
      rows: items.map do |item|
        row = { id: item["id"], title: item["title"].to_s.truncate(24) }
        row[:description] = item["description"].to_s.truncate(72) if item["description"].present?
        row
      end
    }]
  end

  private

  def validate_menu_items
    items = parsed_menu_items
    if items.empty?
      errors.add(:menu_items, "must have at least 1 item")
      return
    end

    if items.length > 10
      errors.add(:menu_items, "can have at most 10 items")
    end

    items.each_with_index do |item, i|
      if item["title"].blank?
        errors.add(:base, "Item #{i + 1} title is required")
      elsif item["title"].to_s.length > 24
        errors.add(:base, "Item #{i + 1} title must be 24 characters or less")
      end

      if item["reply_text"].blank?
        errors.add(:base, "Item #{i + 1} reply text is required")
      end
    end
  end
end
