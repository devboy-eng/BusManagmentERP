class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :authorize_feature!

  include Pagy::Backend

  helper_method :can_access?

  layout :layout_by_resource

  CONTROLLER_FEATURE_MAP = {
    "dashboard" => :dashboard, "customers" => :customers, "vehicles" => :vehicles,
    "job_cards" => :job_cards, "inspections" => :job_cards,
    "estimates" => :estimates, "invoices" => :estimates, "payments" => :estimates,
    "spare_parts" => :inventory, "suppliers" => :inventory, "warehouses" => :inventory,
    "purchase_orders" => :inventory, "inventory_movements" => :inventory,
    "technicians" => :technicians, "technician_assignments" => :technicians,
    "service_types" => :dashboard, "branches" => :dashboard,
    "service_reminders" => :vehicles, "reports" => :reports,
    "users" => :users, "roles" => :roles,
    "whatsapp_chats" => :whatsapp, "whatsapp_marketing" => :whatsapp
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

  def require_super_admin!
    unless current_user&.super_admin?
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
