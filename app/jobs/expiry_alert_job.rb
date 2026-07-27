class ExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    thirty_days = Date.current + 30.days
    expiring = Vehicle.where("insurance_expiry_date <= ? OR fitness_certificate_expiry <= ? OR puc_expiry_date <= ?",
      thirty_days, thirty_days, thirty_days)
    Rails.logger.info "Expiry alert: #{expiring.count} vehicles with expiring documents"
  end
end
