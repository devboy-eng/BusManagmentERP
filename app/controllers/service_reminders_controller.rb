class ServiceRemindersController < ApplicationController
  before_action :set_reminder, only: [:edit, :update, :destroy]

  def index
    @reminders = ServiceReminder.includes(:vehicle, :customer).order(due_date: :asc)
    if params[:status].present?
      @reminders = @reminders.where(status: params[:status])
    end
    @pagy, @reminders = pagy(@reminders, items: 15)
  end

  def new
    @reminder = ServiceReminder.new
    @vehicles = Vehicle.active_vehicles.order(:registration_number)
  end

  def create
    @reminder = ServiceReminder.new(reminder_params)
    @reminder.created_by = current_user
    @reminder.customer = @reminder.vehicle&.customer
    if @reminder.save
      redirect_to service_reminders_path, notice: "Reminder created."
    else
      @vehicles = Vehicle.active_vehicles.order(:registration_number)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @vehicles = Vehicle.active_vehicles.order(:registration_number)
  end

  def update
    if @reminder.update(reminder_params)
      redirect_to service_reminders_path, notice: "Reminder updated."
    else
      @vehicles = Vehicle.active_vehicles.order(:registration_number)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy
    redirect_to service_reminders_path, notice: "Reminder deleted."
  end

  private

  def set_reminder
    @reminder = ServiceReminder.find(params[:id])
  end

  def reminder_params
    params.require(:service_reminder).permit(:vehicle_id, :reminder_type, :due_date, :odometer_due_at, :status, :notes)
  end
end
