class WhatsappTemplate < ApplicationRecord
  belongs_to :user

  STATUSES = %w[draft pending approved rejected paused disabled].freeze

  HEADER_TYPES = %w[none text image video document].freeze

  CATEGORIES = %w[marketing utility authentication].freeze

  LANGUAGES = {
    "af" => "Afrikaans", "sq" => "Albanian", "ar" => "Arabic", "az" => "Azerbaijani",
    "bn" => "Bengali", "bg" => "Bulgarian", "ca" => "Catalan", "zh_CN" => "Chinese (Simplified)",
    "zh_HK" => "Chinese (Hong Kong)", "zh_TW" => "Chinese (Traditional)", "hr" => "Croatian",
    "cs" => "Czech", "da" => "Danish", "nl" => "Dutch", "en" => "English", "en_GB" => "English (UK)",
    "en_US" => "English (US)", "et" => "Estonian", "fil" => "Filipino", "fi" => "Finnish",
    "fr" => "French", "ka" => "Georgian", "de" => "German", "el" => "Greek",
    "gu" => "Gujarati", "ha" => "Hausa", "he" => "Hebrew", "hi" => "Hindi",
    "hu" => "Hungarian", "id" => "Indonesian", "ga" => "Irish", "it" => "Italian",
    "ja" => "Japanese", "kn" => "Kannada", "kk" => "Kazakh", "rw_RW" => "Kinyarwanda",
    "ko" => "Korean", "ky_KG" => "Kyrgyz", "lo" => "Lao", "lv" => "Latvian",
    "lt" => "Lithuanian", "mk" => "Macedonian", "ms" => "Malay", "ml" => "Malayalam",
    "mr" => "Marathi", "nb" => "Norwegian", "fa" => "Persian", "pl" => "Polish",
    "pt_BR" => "Portuguese (Brazil)", "pt_PT" => "Portuguese (Portugal)", "pa" => "Punjabi",
    "ro" => "Romanian", "ru" => "Russian", "sr" => "Serbian", "sk" => "Slovak",
    "sl" => "Slovenian", "es" => "Spanish", "es_AR" => "Spanish (Argentina)",
    "es_MX" => "Spanish (Mexico)", "sw" => "Swahili", "sv" => "Swedish",
    "ta" => "Tamil", "te" => "Telugu", "th" => "Thai", "tr" => "Turkish",
    "uk" => "Ukrainian", "ur" => "Urdu", "uz" => "Uzbek", "vi" => "Vietnamese",
    "zu" => "Zulu"
  }.freeze

  validates :name, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
  validates :header_type, inclusion: { in: HEADER_TYPES }, allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :language, inclusion: { in: LANGUAGES.keys }, allow_nil: true
  validates :header_text, presence: true, if: -> { header_type == "text" }
  validates :header_media_url, presence: true, if: -> { header_type.in?(%w[image video document]) }

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
end
