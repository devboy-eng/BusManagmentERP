class SyncWhatsappQualityJob < ApplicationJob
  queue_as :default

  QUALITY_ORDER = %w[GREEN YELLOW RED].freeze

  def perform
    setting = WhatsappSetting.first
    return unless setting&.active?

    result = WhatsappService.fetch_phone_numbers(
      access_token: setting.access_token,
      business_account_id: setting.business_account_id
    )

    unless result[:success]
      Rails.logger.error "[SyncWhatsappQuality] Failed to fetch phone numbers: #{result[:error]}"
      return
    end

    phone_data = result[:phone_numbers].find { |p| p["id"] == setting.phone_number_id }
    unless phone_data
      Rails.logger.warn "[SyncWhatsappQuality] Phone number #{setting.phone_number_id} not found in API response"
      return
    end

    new_quality = phone_data["quality_rating"]&.upcase
    new_limit = phone_data["messaging_limit_tier"] || phone_data["throughput"]&.dig("level")
    old_quality = setting.quality_rating

    # Detect quality degradation
    if old_quality.present? && new_quality.present?
      old_index = QUALITY_ORDER.index(old_quality.upcase) || 0
      new_index = QUALITY_ORDER.index(new_quality) || 0
      if new_index > old_index
        Rails.logger.warn "[SyncWhatsappQuality] Quality degraded: #{old_quality} -> #{new_quality} for phone #{setting.phone_number_id}"
      end
    end

    setting.update!(
      quality_rating: new_quality,
      messaging_limit: new_limit.to_s,
      quality_updated_at: Time.current
    )

    Rails.logger.info "[SyncWhatsappQuality] Updated: quality=#{new_quality}, limit=#{new_limit}"

    # Fetch phone number details
    details_result = WhatsappService.fetch_phone_details(
      access_token: setting.access_token,
      phone_number_id: setting.phone_number_id
    )

    if details_result[:success]
      data = details_result[:data]
      setting.update!(
        phone_display_number: data["display_phone_number"],
        verified_name: data["verified_name"],
        name_status: data["name_status"],
        phone_status: data["status"],
        code_verification_status: data["code_verification_status"],
        platform_type: data["platform_type"]
      )
      Rails.logger.info "[SyncWhatsappQuality] Phone details updated"
    else
      Rails.logger.warn "[SyncWhatsappQuality] Failed to fetch phone details: #{details_result[:error]}"
    end

    # Fetch business profile
    profile_result = WhatsappService.fetch_business_profile(
      access_token: setting.access_token,
      phone_number_id: setting.phone_number_id
    )

    if profile_result[:success]
      data = profile_result[:data]
      setting.update!(
        business_about: data["about"],
        business_description: data["description"],
        business_address: data["address"],
        business_email: data["email"],
        business_websites: data["websites"]&.to_json,
        business_vertical: data["vertical"],
        profile_picture_url: data["profile_picture_url"],
        profile_synced_at: Time.current
      )
      Rails.logger.info "[SyncWhatsappQuality] Business profile updated"
    else
      Rails.logger.warn "[SyncWhatsappQuality] Failed to fetch business profile: #{profile_result[:error]}"
    end
  rescue => e
    Rails.logger.error "[SyncWhatsappQuality] Error: #{e.class}: #{e.message}"
  end
end
