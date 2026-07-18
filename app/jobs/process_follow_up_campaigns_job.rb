class ProcessFollowUpCampaignsJob < ApplicationJob
  queue_as :default

  def perform
    FollowUpCampaign.due.find_each do |campaign|
      process_campaign(campaign)
    end
  end

  private

  def process_campaign(campaign)
    campaign.update!(status: :processing)
    service = WhatsappService.new
    template = campaign.whatsapp_template
    variables = campaign.parsed_template_variables

    campaign.contacts.queued.find_each do |contact|
      send_to_contact(service, template, variables, contact, campaign.user)
      sleep 0.2
    end

    campaign.update!(status: :completed)
    campaign.update_counts!
  rescue => e
    Rails.logger.error "[FollowUpCampaign] Error processing campaign #{campaign.id}: #{e.class}: #{e.message}"
    campaign.update_counts!
    campaign.update!(status: :completed) if campaign.processing?
  end

  def send_to_contact(service, template, variables, contact, user)
    # If the contact has a lead or customer, use send_template_and_log for conversation tracking
    if contact.lead.present? || contact.customer.present?
      recipient = contact.lead || contact.customer
      outcome = service.send_template_and_log(
        recipient: recipient,
        template: template,
        variables: variables,
        user: user
      )

      if outcome[:result][:success]
        contact.update!(
          status: :sent,
          whatsapp_message_id: outcome[:result][:message_id],
          sent_at: Time.current
        )
      else
        contact.update!(
          status: :failed,
          error_message: outcome[:result][:error]
        )
      end
    else
      # CSV contact without a lead — send template directly
      result = service.send_template_message(
        phone: contact.phone,
        template: template,
        variables: variables
      )

      if result[:success]
        contact.update!(
          status: :sent,
          whatsapp_message_id: result[:message_id],
          sent_at: Time.current
        )
      else
        contact.update!(
          status: :failed,
          error_message: result[:error]
        )
      end
    end
  rescue WhatsappService::NonRetryableError => e
    contact.update!(status: :failed, error_message: "Permanent: #{e.message}")
  rescue => e
    contact.update!(status: :failed, error_message: e.message)
  end
end
