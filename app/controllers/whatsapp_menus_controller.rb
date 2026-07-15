class WhatsappMenusController < ApplicationController
  before_action :set_menu, only: [:edit, :update, :destroy, :toggle, :send_menu]

  def index
    @menus = WhatsappMenu.ordered
  end

  def new
    @menu = WhatsappMenu.new(button_text: "Menu")
  end

  def create
    @menu = WhatsappMenu.new(menu_params)
    @menu.user = current_user

    if @menu.save
      redirect_to whatsapp_menus_path, notice: "Interactive menu created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @menu.update(menu_params)
      redirect_to whatsapp_menus_path, notice: "Interactive menu updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @menu.destroy
    redirect_to whatsapp_menus_path, notice: "Interactive menu deleted.", status: :see_other
  end

  def toggle
    @menu.update!(active: !@menu.active)
    redirect_to whatsapp_menus_path, notice: "Menu #{@menu.active? ? 'activated' : 'deactivated'}.", status: :see_other
  end

  # Manually send this menu to a specific conversation
  def send_menu
    conversation = WhatsappConversation.find(params[:conversation_id])

    service = WhatsappService.new
    result = service.send_interactive_list(
      phone: conversation.contact_phone,
      header: @menu.header_text,
      body: @menu.body_text,
      footer: @menu.footer_text,
      button_text: @menu.button_text,
      sections: @menu.api_sections
    )

    if result[:success]
      display = "📋 #{@menu.name}\n#{@menu.body_text}"

      message = WhatsappMessage.create!(
        recipient_phone: conversation.contact_phone,
        message_body: display,
        direction: "outgoing",
        whatsapp_conversation: conversation,
        whatsapp_message_id: result[:message_id],
        status: :sent,
        message_type: "text"
      )

      conversation.update_last_message!(message)
      redirect_to whatsapp_chat_path(conversation), notice: "Menu sent successfully."
    else
      redirect_to whatsapp_menus_path, alert: "Failed to send menu: #{result[:error]}"
    end
  rescue WhatsappService::ApiError => e
    redirect_to whatsapp_menus_path, alert: e.message
  end

  private

  def set_menu
    @menu = WhatsappMenu.find(params[:id])
  end

  def menu_params
    params.require(:whatsapp_menu).permit(:name, :header_text, :body_text, :footer_text, :button_text, :trigger_keyword, :active, :menu_items)
  end
end
