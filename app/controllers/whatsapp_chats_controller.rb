class WhatsappChatsController < ApplicationController
  before_action :load_conversations, only: [:index, :show]
  before_action :load_conversation, only: [:show, :send_reply, :mark_read]

  def index
    @selected = @conversations.first
    if @selected
      @messages = @selected.whatsapp_messages.chronological
      @selected.mark_as_read!
    end
  end

  def show
    @selected = @conversation
    @messages = @conversation.whatsapp_messages.chronological
    @conversation.mark_as_read!

    respond_to do |format|
      format.html { render :index }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("chat-area",
            partial: "whatsapp_chats/chat_area",
            locals: { conversation: @conversation, messages: @messages }
          ),
          turbo_stream.replace("conversation-list",
            partial: "whatsapp_chats/conversation_list",
            locals: { conversations: @conversations, selected: @conversation }
          )
        ]
      end
    end
  end

  def send_reply
    body = params[:message_body]&.strip
    if body.blank?
      head :unprocessable_entity
      return
    end

    # WhatsApp max message length is 4096 characters
    if body.length > 4096
      return render_form_error("Message too long. WhatsApp allows maximum 4096 characters.")
    end

    # Meta 24-hour policy: free-form messages only allowed within 24h of customer's last message.
    # Outside this window Meta will reject the API call and flag the number.
    unless @conversation.within_reply_window?
      return render_form_error("Cannot send — the 24-hour customer service window has expired. The customer must message you first before you can reply.")
    end

    begin
      service = WhatsappService.new

      # Find or create recipient from conversation contact
      recipient = @conversation.contact
      if recipient
        # send_and_log handles broadcasting to chat UI
        result = service.send_and_log(recipient: recipient, message: body, user: current_user)
        message = result[:record]
      else
        # No linked contact — send directly and create message manually
        api_result = service.send_text_message(phone: @conversation.contact_phone, text: body)

        message = WhatsappMessage.create!(
          recipient_phone: @conversation.contact_phone,
          recipient_name: @conversation.contact_name,
          message_body: body,
          user: current_user,
          direction: "outgoing",
          whatsapp_conversation: @conversation,
          status: api_result[:success] ? :sent : :failed,
          whatsapp_message_id: api_result[:message_id],
          error_message: api_result[:error]
        )

        @conversation.update_last_message!(message)

        # Broadcast manually since we didn't go through send_and_log
        broadcast_new_message(@conversation, message)
        broadcast_conversation_update(@conversation)
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("message-form",
            partial: "whatsapp_chats/message_form",
            locals: { conversation: @conversation }
          )
        end
      end
    rescue WhatsappService::ApiError => e
      render_form_error(e.message)
    end
  end

  def mark_read
    @conversation.mark_as_read!
    head :ok
  end

  def send_to_lead
    @conversation = WhatsappConversation.find(params[:id])

    # Check if conversation is already linked to a lead
    if @conversation.contact_type == "Lead" && @conversation.contact.present?
      redirect_to whatsapp_chat_path(@conversation), notice: "This conversation is already linked to a lead.", status: :see_other
      return
    end

    # Check if a lead with this phone already exists
    phone = @conversation.contact_phone
    existing_lead = Lead.find_by(phone: phone) ||
                    Lead.find_by(phone: phone&.gsub(/\D/, "")&.last(10)) ||
                    Lead.find_by(phone: "+91#{phone&.gsub(/\D/, '')&.last(10)}")

    if existing_lead
      @conversation.update!(contact: existing_lead, contact_name: existing_lead.name)
      redirect_to whatsapp_chat_path(@conversation), notice: "Conversation linked to existing lead: #{existing_lead.name}", status: :see_other
    else
      lead = Lead.new(
        name: @conversation.contact_name.presence || "WhatsApp Lead",
        phone: phone,
        user: current_user,
        status: :pending
      )

      if lead.save
        @conversation.update!(contact: lead, contact_name: lead.name)
        redirect_to whatsapp_chat_path(@conversation), notice: "Lead created successfully! #{lead.name} has been added to your leads.", status: :see_other
      else
        redirect_to whatsapp_chat_path(@conversation), alert: "Failed to create lead: #{lead.errors.full_messages.join(', ')}", status: :see_other
      end
    end
  end

  private

  def load_conversations
    @conversations = WhatsappConversation.ordered
  end

  def load_conversation
    @conversation = WhatsappConversation.find(params[:id])
  end

  def render_form_error(error_msg)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("message-form",
          partial: "whatsapp_chats/message_form",
          locals: { conversation: @conversation, error: error_msg }
        )
      end
    end
  end

  def broadcast_new_message(conversation, message)
    html = render_to_string(
      partial: "whatsapp_chats/message",
      locals: { message: message },
      formats: [:html]
    )

    WhatsappChatChannel.broadcast_to(
      conversation,
      { type: "new_message", html: html }
    )
  end

  def broadcast_conversation_update(conversation)
    html = render_to_string(
      partial: "whatsapp_chats/conversation",
      locals: { conversation: conversation, selected: false },
      formats: [:html]
    )

    ActionCable.server.broadcast(
      "whatsapp_conversations",
      { type: "conversation_update", conversation_id: conversation.id, html: html }
    )
  end
end
