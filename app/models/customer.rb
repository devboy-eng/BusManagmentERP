class Customer < ApplicationRecord
  belongs_to :user, optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :whatsapp_messages, as: :recipient, dependent: :nullify
  has_many :whatsapp_conversations, as: :contact, dependent: :nullify
  has_many :csat_responses, as: :respondent, dependent: :nullify

  enum :status, { active: 0, non_active: 1 }, default: :active

  validates :name, presence: true
  validates :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def self.ransackable_attributes(auth_object = nil)
    %w[name phone email address pan gst trademark status created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
