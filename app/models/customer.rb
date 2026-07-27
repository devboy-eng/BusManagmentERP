class Customer < ApplicationRecord
  belongs_to :user, optional: true
  has_many :vehicles, dependent: :destroy
  has_many :job_cards, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :payments
  has_many :service_reminders
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :whatsapp_messages, as: :recipient, dependent: :nullify
  has_many :whatsapp_conversations, as: :contact, dependent: :nullify

  enum :status, { active: 0, non_active: 1 }, default: :active
  enum :customer_type, { individual: 0, company: 1, fleet_owner: 2, government: 3 }

  scope :whatsapp_opted_in, -> { where(whatsapp_opt_out: false) }

  validates :name, presence: true
  validates :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def self.ransackable_attributes(auth_object = nil)
    %w[name phone email address gst status customer_type created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
