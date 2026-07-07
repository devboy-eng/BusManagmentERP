class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  FEATURES = {
    dashboard:  "Dashboard",
    customers:  "Customers",
    leads:      "Leads",
    users:      "Users",
    roles:      "Roles & Privileges",
    whatsapp:   "WhatsApp Marketing"
  }.freeze

  serialize :permissions, coder: JSON

  def permissions
    value = super
    value.is_a?(String) ? JSON.parse(value) : value
  end

  after_initialize :set_default_permissions, if: :new_record?

  belongs_to :role, optional: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_inactive
  end
  has_many :comments, dependent: :destroy
  has_many :customers
  has_many :leads
  has_many :whatsapp_messages
  has_many :whatsapp_templates
  has_many :follow_ups

  def super_admin?
    role&.name == "Super Admin"
  end

  def admin?
    role&.name == "Admin"
  end

  def supervisor?
    role&.name == "Supervisor"
  end

  def role_name
    role&.name || "No Role"
  end

  def can_access?(feature)
    return true if super_admin?

    permissions&.dig(feature.to_s) != false
  end

  def self.default_permissions
    FEATURES.keys.each_with_object({}) { |key, hash| hash[key.to_s] = true }
  end

  private

  def set_default_permissions
    self.permissions ||= self.class.default_permissions
  end
end
