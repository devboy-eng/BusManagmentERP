class Lead < ApplicationRecord
  belongs_to :user, optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :whatsapp_messages, as: :recipient, dependent: :nullify
  has_many :follow_ups, dependent: :destroy

  enum :status, { pending: 0, not_interested: 1, work_in_process: 2, contacted: 3, follow_up: 4 }, default: :pending

  validates :name, presence: true
  validates :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  CATEGORIES = [
    "Trademark",
    "GST Registration",
    "Startup Certificate",
    "Company Registration",
    "Income Tax",
    "Other"
  ].freeze

  def self.ransackable_attributes(auth_object = nil)
    %w[name phone email address pan gst trademark status category created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def status_color
    case status
    when "pending" then "yellow"
    when "not_interested" then "red"
    when "work_in_process" then "blue"
    when "contacted" then "green"
    when "follow_up" then "purple"
    end
  end
end
