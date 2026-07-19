class WhatsappChatsController < ApplicationController
  before_action :load_conversations, only: [:index, :show]
  before_action :load_conversation, only: [:show, :send_reply, :mark_read, :send_media, :react, :assign, :unassign, :schedule_message]

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
          turbo_stream.update("chat-area",
            partial: "whatsapp_chats/chat_area",
            locals: { conversation: @conversation, messages: @messages }
          ),
          turbo_stream.update("conversation-list",
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

    unless @conversation.within_reply_window?
      return render_form_error(
        "The 24-hour reply window has expired. Please use an approved template to re-initiate contact."
      )
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

  def send_media
    media_url = params[:media_url]&.strip
    media_type = params[:media_type] || "image"
    caption = params[:caption]&.strip
    filename = params[:filename]

    if media_url.blank?
      return render json: { error: "Media URL is required" }, status: :unprocessable_entity
    end

    begin
      service = WhatsappService.new

      api_result = service.send_media_message(
        phone: @conversation.contact_phone,
        type: media_type,
        media_url: media_url,
        caption: caption,
        filename: filename
      )

      message = WhatsappMessage.create!(
        recipient_phone: @conversation.contact_phone,
        recipient_name: @conversation.contact_name,
        recipient: @conversation.contact,
        message_body: caption,
        message_type: media_type,
        media_url: media_url,
        media_caption: caption,
        media_filename: filename,
        user: current_user,
        direction: "outgoing",
        whatsapp_conversation: @conversation,
        status: api_result[:success] ? :sent : :failed,
        whatsapp_message_id: api_result[:message_id],
        error_message: api_result[:error]
      )

      @conversation.update_last_message!(message)
      broadcast_new_message(@conversation, message)
      broadcast_conversation_update(@conversation)

      render json: { success: true, message_id: message.id }
    rescue WhatsappService::ApiError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def react
    message = WhatsappMessage.find(params[:message_id])
    emoji = params[:emoji]

    if emoji.blank?
      return render json: { error: "Emoji is required" }, status: :unprocessable_entity
    end

    begin
      service = WhatsappService.new
      result = service.send_reaction(
        phone: @conversation.contact_phone,
        message_id: message.whatsapp_message_id,
        emoji: emoji
      )

      if result[:success]
        reaction_record = WhatsappMessage.create!(
          recipient_phone: @conversation.contact_phone,
          message_type: "reaction",
          reaction_emoji: emoji,
          context_message_id: message.whatsapp_message_id,
          direction: "outgoing",
          whatsapp_conversation: @conversation,
          whatsapp_message_id: result[:message_id],
          user: current_user,
          status: :sent
        )

        broadcast_new_message(@conversation, reaction_record)
        render json: { success: true }
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue WhatsappService::ApiError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def assign
    user = User.find(params[:user_id])
    @conversation.update!(assigned_user: user)

    respond_to do |format|
      format.turbo_stream do
        @messages = @conversation.whatsapp_messages.chronological
        @conversations = WhatsappConversation.includes(:assigned_user).ordered
        render turbo_stream: [
          turbo_stream.update("chat-area",
            partial: "whatsapp_chats/chat_area",
            locals: { conversation: @conversation, messages: @messages }
          ),
          turbo_stream.update("conversation-list",
            partial: "whatsapp_chats/conversation_list",
            locals: { conversations: @conversations, selected: @conversation }
          )
        ]
      end
      format.html { redirect_to whatsapp_chat_path(@conversation), notice: "Conversation assigned to #{user.name}", status: :see_other }
    end
  end

  def unassign
    @conversation.update!(assigned_user: nil)

    respond_to do |format|
      format.turbo_stream do
        @messages = @conversation.whatsapp_messages.chronological
        @conversations = WhatsappConversation.includes(:assigned_user).ordered
        render turbo_stream: [
          turbo_stream.update("chat-area",
            partial: "whatsapp_chats/chat_area",
            locals: { conversation: @conversation, messages: @messages }
          ),
          turbo_stream.update("conversation-list",
            partial: "whatsapp_chats/conversation_list",
            locals: { conversations: @conversations, selected: @conversation }
          )
        ]
      end
      format.html { redirect_to whatsapp_chat_path(@conversation), notice: "Conversation unassigned", status: :see_other }
    end
  end

  def schedule_message
    scheduled = ScheduledMessage.new(
      whatsapp_conversation: @conversation,
      message_body: params[:message_body],
      scheduled_at: params[:scheduled_at],
      user: current_user
    )

    if scheduled.save
      render json: { success: true, id: scheduled.id }
    else
      render json: { error: scheduled.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def search
    query = params[:q]&.strip
    if query.blank?
      return render json: { results: [] }
    end

    messages = WhatsappMessage.search_content(query)
                              .includes(:whatsapp_conversation)
                              .recent
                              .limit(50)

    results = messages.map do |msg|
      {
        id: msg.id,
        body: msg.message_body&.truncate(100),
        conversation_id: msg.whatsapp_conversation_id,
        conversation_name: msg.whatsapp_conversation&.display_name,
        direction: msg.direction,
        created_at: msg.created_at.strftime("%b %d, %I:%M %p")
      }
    end

    render json: { results: results }
  end

  def send_to_lead
    @conversation = WhatsappConversation.find(params[:id])

    # Check if conversation is already linked to a lead/customer
    if @conversation.contact.present?
      redirect_to whatsapp_chat_path(@conversation), notice: "This conversation is already linked to a #{@conversation.contact_type.downcase}.", status: :see_other
      return
    end

    lead_params = params.require(:lead).permit(:name, :phone, :email, :category)
    phone = lead_params[:phone].presence || @conversation.contact_phone

    # Check if a lead with this phone already exists
    existing_lead = Lead.find_by(phone: phone) ||
                    Lead.find_by(phone: phone&.gsub(/\D/, "")&.last(10)) ||
                    Lead.find_by(phone: "+91#{phone&.gsub(/\D/, '')&.last(10)}")

    if existing_lead
      # Update existing lead with any new info provided
      existing_lead.update(
        email: lead_params[:email].presence || existing_lead.email,
        category: lead_params[:category].presence || existing_lead.category
      )
      @conversation.update!(contact: existing_lead, contact_name: existing_lead.name)
      redirect_to whatsapp_chat_path(@conversation), notice: "Conversation linked to existing lead: #{existing_lead.name}", status: :see_other
    else
      lead = Lead.new(
        name: lead_params[:name].presence || @conversation.contact_name.presence || "WhatsApp Lead",
        phone: phone,
        email: lead_params[:email],
        category: lead_params[:category],
        user: current_user,
        status: :pending
      )

      if lead.save
        @conversation.update!(contact: lead, contact_name: lead.name)
        redirect_to whatsapp_chat_path(@conversation), notice: "Lead created: #{lead.name} has been added to your leads.", status: :see_other
      else
        redirect_to whatsapp_chat_path(@conversation), alert: "Failed to create lead: #{lead.errors.full_messages.join(', ')}", status: :see_other
      end
    end
  end

  private

  def load_conversations
    @conversations = WhatsappConversation.includes(:assigned_user).ordered
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
