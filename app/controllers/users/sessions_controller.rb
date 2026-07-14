class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: []

  def create
    user = User.find_by(email: params[:user][:email])

    if user&.valid_password?(params[:user][:password])
      unless user.active_for_authentication?
        set_flash_message!(:alert, user.inactive_message)
        redirect_to new_session_path(resource_name) and return
      end

      # If OTP is enabled for this user, has a phone number, and WhatsApp is configured, require OTP
      if user.otp_enabled? && user.has_phone_for_otp? && WhatsappSetting.configured?
        user.generate_otp!
        send_otp_to_user(user)
        session[:otp_user_id] = user.id
        redirect_to verify_otp_path
      else
        # No OTP required — sign in directly
        sign_in(:user, user)
        redirect_to after_sign_in_path_for(user), notice: "Signed in successfully."
      end
    else
      set_flash_message!(:alert, :invalid)
      redirect_to new_session_path(resource_name)
    end
  end

  def verify_otp
    unless session[:otp_user_id]
      redirect_to new_session_path(:user) and return
    end

    @user = User.find_by(id: session[:otp_user_id])
    unless @user
      session.delete(:otp_user_id)
      redirect_to new_session_path(:user), alert: "Session expired. Please sign in again." and return
    end

    @masked_phone = mask_phone(@user.phone)
    render layout: "devise"
  end

  def confirm_otp
    unless session[:otp_user_id]
      redirect_to new_session_path(:user), alert: "Session expired. Please sign in again." and return
    end

    @user = User.find_by(id: session[:otp_user_id])
    unless @user
      session.delete(:otp_user_id)
      redirect_to new_session_path(:user), alert: "Session expired. Please sign in again." and return
    end

    if @user.otp_expired?
      @masked_phone = mask_phone(@user.phone)
      flash.now[:alert] = "OTP has expired. Please request a new one."
      render :verify_otp, layout: "devise" and return
    end

    if @user.verify_otp(params[:otp_code])
      @user.clear_otp!
      session.delete(:otp_user_id)
      sign_in(:user, @user)
      redirect_to after_sign_in_path_for(@user), notice: "Signed in successfully."
    else
      @masked_phone = mask_phone(@user.phone)
      flash.now[:alert] = "Invalid OTP. Please try again."
      render :verify_otp, layout: "devise"
    end
  end

  def resend_otp
    unless session[:otp_user_id]
      redirect_to new_session_path(:user), alert: "Session expired. Please sign in again." and return
    end

    @user = User.find_by(id: session[:otp_user_id])
    unless @user
      session.delete(:otp_user_id)
      redirect_to new_session_path(:user), alert: "Session expired. Please sign in again." and return
    end

    # Rate limit: 30-second cooldown
    if @user.otp_sent_at.present? && @user.otp_sent_at > 30.seconds.ago
      redirect_to verify_otp_path, alert: "Please wait before requesting a new OTP." and return
    end

    @user.generate_otp!
    send_otp_to_user(@user)
    redirect_to verify_otp_path, notice: "A new OTP has been sent to your WhatsApp."
  end

  private

  def send_otp_to_user(user)
    template = WhatsappTemplate.find_by(category: "authentication", status: "approved")

    service = WhatsappService.new

    if template
      message_body = "Login OTP: #{user.otp_code} (via template: #{template.name})"
      result = service.send_template_message(
        phone: user.phone,
        template: template,
        variables: [user.otp_code]
      )
    else
      message_body = "Your FinanceERP login OTP is: #{user.otp_code}. Valid for 5 minutes. Do not share this code."
      result = service.send_text_message(
        phone: user.phone,
        text: message_body
      )
    end

    # Log OTP message to WhatsApp Message Log
    WhatsappMessage.create!(
      recipient: user,
      recipient_name: user.name,
      recipient_phone: user.phone,
      message_body: message_body,
      user: user,
      direction: "outgoing",
      status: result&.dig(:success) ? :sent : :failed,
      whatsapp_message_id: result&.dig(:message_id),
      error_message: result&.dig(:error)
    )
  rescue WhatsappService::ApiError => e
    Rails.logger.error "[OTP] WhatsApp send failed: #{e.message}"
    WhatsappMessage.create(
      recipient: user,
      recipient_name: user.name,
      recipient_phone: user.phone,
      message_body: "Login OTP (failed to send)",
      user: user,
      direction: "outgoing",
      status: :failed,
      error_message: e.message
    )
  end

  def mask_phone(phone)
    return "****" if phone.blank?
    digits = phone.gsub(/\D/, "")
    "****#{digits.last(2)}"
  end
end
