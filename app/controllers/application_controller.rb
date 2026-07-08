class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :authorize_feature!

  include Pagy::Backend

  helper_method :can_access?

  layout :layout_by_resource

  CONTROLLER_FEATURE_MAP = {
    "dashboard"            => :dashboard,
    "customers"            => :customers,
    "leads"                => :leads,
    "users"                => :users,
    "roles"                => :roles,
    "whatsapp_marketing"   => :whatsapp,
    "whatsapp_settings"    => :whatsapp,
    "whatsapp_templates"   => :whatsapp,
    "follow_ups"           => :whatsapp,
    "whatsapp_chats"       => :whatsapp
  }.freeze

  private

  def authorize_feature!
    return if devise_controller?
    return if current_user&.super_admin?

    feature = CONTROLLER_FEATURE_MAP[controller_name]
    return if feature.nil?

    unless current_user&.can_access?(feature)
      redirect_to root_path, alert: "You do not have access to this feature."
    end
  end

  def can_access?(feature)
    return true if current_user&.super_admin?

    current_user&.can_access?(feature)
  end

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end
end
