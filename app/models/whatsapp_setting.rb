class WhatsappSetting < ApplicationRecord
  validates :phone_number_id, presence: true, if: :active?
  validates :access_token, presence: true, if: :active?

  before_create :generate_verify_token

  def self.instance
    first_or_create
  end

  def self.configured?
    setting = first
    setting.present? && setting.active? && setting.phone_number_id.present? && setting.access_token.present?
  end

  private

  def generate_verify_token
    self.verify_token = SecureRandom.hex(16) if verify_token.blank?
  end
end
