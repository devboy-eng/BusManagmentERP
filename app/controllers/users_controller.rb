class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy, :toggle_status]

  def index
    @users = User.includes(:role).order(created_at: :desc)
    @pagy, @users = pagy(@users, items: 15)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: "User created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    update_params = user_params
    update_params = update_params.except(:password, :password_confirmation) if update_params[:password].blank?
    if @user.update(update_params)
      redirect_to users_path, notice: "User updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: "You cannot delete yourself."
    else
      @user.destroy
      redirect_to users_path, notice: "User deleted successfully."
    end
  end

  def toggle_status
    if @user == current_user
      redirect_to users_path, alert: "You cannot deactivate yourself."
    else
      @user.update(active: !@user.active?)
      status_label = @user.active? ? "activated" : "deactivated"
      redirect_to users_path, notice: "User #{status_label} successfully."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = params.require(:user).permit(:name, :email, :phone, :role_id, :password, :password_confirmation, :active, permissions: {})

    if permitted[:permissions].present?
      permitted[:permissions] = permitted[:permissions].transform_values { |v| v == "1" }
    end

    permitted
  end
end
