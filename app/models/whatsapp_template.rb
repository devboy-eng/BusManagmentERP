class WhatsappTemplate < ApplicationRecord
  belongs_to :user

  STATUSES = %w[draft pending approved rejected paused disabled].freeze

  HEADER_TYPES = %w[none text image video document].freeze

  CATEGORIES = %w[marketing utility authentication].freeze

  TEMPLATE_TYPES = %w[standard carousel].freeze

  BUTTON_TYPES = %w[QUICK_REPLY URL PHONE_NUMBER COPY_CODE].freeze
  CTA_BUTTON_TYPES = %w[URL PHONE_NUMBER COPY_CODE].freeze

  LANGUAGES = {
    "af" => "Afrikaans", "sq" => "Albanian", "ar" => "Arabic", "ar_EG" => "Arabic (Egypt)",
    "ar_AE" => "Arabic (UAE)", "ar_LB" => "Arabic (Lebanon)", "ar_MA" => "Arabic (Morocco)",
    "ar_QA" => "Arabic (Qatar)", "az" => "Azerbaijani", "be_BY" => "Belarusian",
    "bn" => "Bengali", "bn_IN" => "Bengali (India)", "bg" => "Bulgarian", "ca" => "Catalan",
    "zh_CN" => "Chinese (Simplified)", "zh_HK" => "Chinese (Hong Kong)",
    "zh_TW" => "Chinese (Traditional)", "hr" => "Croatian", "cs" => "Czech", "da" => "Danish",
    "prs_AF" => "Dari", "nl" => "Dutch", "nl_BE" => "Dutch (Belgium)",
    "en" => "English", "en_GB" => "English (UK)", "en_US" => "English (US)",
    "en_AE" => "English (UAE)", "en_AU" => "English (Australia)", "en_CA" => "English (Canada)",
    "en_GH" => "English (Ghana)", "en_IE" => "English (Ireland)", "en_IN" => "English (India)",
    "en_JM" => "English (Jamaica)", "en_MY" => "English (Malaysia)",
    "en_NZ" => "English (New Zealand)", "en_QA" => "English (Qatar)",
    "en_SG" => "English (Singapore)", "en_UG" => "English (Uganda)",
    "en_ZA" => "English (South Africa)", "et" => "Estonian", "fil" => "Filipino",
    "fi" => "Finnish", "fr" => "French", "fr_BE" => "French (Belgium)",
    "fr_CA" => "French (Canada)", "fr_CH" => "French (Switzerland)",
    "fr_CI" => "French (Ivory Coast)", "fr_MA" => "French (Morocco)",
    "ka" => "Georgian", "de" => "German", "de_AT" => "German (Austria)",
    "de_CH" => "German (Switzerland)", "el" => "Greek", "gu" => "Gujarati",
    "ha" => "Hausa", "he" => "Hebrew", "hi" => "Hindi", "hu" => "Hungarian",
    "id" => "Indonesian", "ga" => "Irish", "it" => "Italian", "ja" => "Japanese",
    "kn" => "Kannada", "kk" => "Kazakh", "rw_RW" => "Kinyarwanda", "ko" => "Korean",
    "ky_KG" => "Kyrgyz", "lo" => "Lao", "lv" => "Latvian", "lt" => "Lithuanian",
    "mk" => "Macedonian", "ms" => "Malay", "ml" => "Malayalam", "mr" => "Marathi",
    "nb" => "Norwegian", "ps_AF" => "Pashto", "fa" => "Persian", "pl" => "Polish",
    "pt_BR" => "Portuguese (Brazil)", "pt_PT" => "Portuguese (Portugal)", "pa" => "Punjabi",
    "ro" => "Romanian", "ru" => "Russian", "sr" => "Serbian", "si_LK" => "Sinhala",
    "sk" => "Slovak", "sl" => "Slovenian", "es" => "Spanish",
    "es_AR" => "Spanish (Argentina)", "es_CL" => "Spanish (Chile)",
    "es_CO" => "Spanish (Colombia)", "es_CR" => "Spanish (Costa Rica)",
    "es_DO" => "Spanish (Dominican Republic)", "es_EC" => "Spanish (Ecuador)",
    "es_HN" => "Spanish (Honduras)", "es_MX" => "Spanish (Mexico)",
    "es_PA" => "Spanish (Panama)", "es_PE" => "Spanish (Peru)",
    "es_ES" => "Spanish (Spain)", "es_UY" => "Spanish (Uruguay)",
    "sw" => "Swahili", "sv" => "Swedish", "ta" => "Tamil", "te" => "Telugu",
    "th" => "Thai", "tr" => "Turkish", "uk" => "Ukrainian", "ur" => "Urdu",
    "uz" => "Uzbek", "vi" => "Vietnamese", "zu" => "Zulu"
  }.freeze

  validates :name, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
  validates :header_type, inclusion: { in: HEADER_TYPES }, allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :language, inclusion: { in: LANGUAGES.keys }, allow_nil: true
  validates :template_type, inclusion: { in: TEMPLATE_TYPES }, allow_nil: true
  validates :header_text, presence: true, length: { maximum: 60 }, if: -> { standard? && header_type == "text" }
  validates :header_media_url, presence: true, if: -> { standard? && header_type.in?(%w[image video document]) }
  validates :body, length: { maximum: 1024 }
  validates :footer, length: { maximum: 60 }
  validate :validate_carousel_cards, if: :carousel?
  validate :validate_buttons

  scope :ordered, -> { order(created_at: :desc) }

  def language_name
    LANGUAGES[language] || language
  end

  def header_display
    case header_type
    when "none", nil then "None"
    when "text" then header_text.presence || "Text"
    when "image" then "Image"
    when "video" then "Video"
    when "document" then "Document"
    else header_type&.titleize
    end
  end

  def standard?
    template_type.blank? || template_type == "standard"
  end

  def carousel?
    template_type == "carousel"
  end

  def parsed_carousel_cards
    return [] if carousel_cards.blank?
    JSON.parse(carousel_cards) rescue []
  end

  def parsed_carousel_cards=(cards)
    self.carousel_cards = cards.to_json
  end

  def parsed_buttons
    val = read_attribute(:buttons)
    return [] if val.blank?
    JSON.parse(val) rescue []
  end

  def parsed_buttons=(btns)
    write_attribute(:buttons, btns.to_json)
  end

  def template_type_display
    carousel? ? "Carousel" : "Standard"
  end

  private

  def validate_buttons
    btns = parsed_buttons
    return if btns.empty?

    has_quick_reply = btns.any? { |b| b["type"] == "QUICK_REPLY" }
    has_cta = btns.any? { |b| b["type"].in?(CTA_BUTTON_TYPES) }

    if has_quick_reply && has_cta
      errors.add(:buttons, "cannot mix Quick Reply and Call-to-Action buttons")
      return
    end

    if has_quick_reply && btns.size > 10
      errors.add(:buttons, "can have at most 10 Quick Reply buttons")
    end

    if has_cta && btns.size > 2
      errors.add(:buttons, "can have at most 2 Call-to-Action buttons")
    end

    btns.each_with_index do |btn, i|
      unless btn["type"].in?(BUTTON_TYPES)
        errors.add(:base, "Button #{i + 1} has an invalid type")
        next
      end

      if btn["text"].blank?
        errors.add(:base, "Button #{i + 1} text is required")
      elsif btn["text"].length > 25
        errors.add(:base, "Button #{i + 1} text must be 25 characters or less")
      end

      if btn["type"] == "URL" && btn["url"].blank?
        errors.add(:base, "Button #{i + 1} URL is required")
      end

      if btn["type"] == "PHONE_NUMBER" && btn["phone_number"].blank?
        errors.add(:base, "Button #{i + 1} phone number is required")
      end
    end
  end

  def validate_carousel_cards
    cards = parsed_carousel_cards
    if cards.length < 2
      errors.add(:carousel_cards, "must have at least 2 cards")
    elsif cards.length > 10
      errors.add(:carousel_cards, "can have at most 10 cards")
    end

    cards.each_with_index do |card, i|
      if card["body"].blank?
        errors.add(:base, "Card #{i + 1} body is required")
      end
      if card["image_url"].blank?
        errors.add(:base, "Card #{i + 1} image URL is required")
      end
    end
  end
end
