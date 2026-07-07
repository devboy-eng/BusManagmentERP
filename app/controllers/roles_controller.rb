class RolesController < ApplicationController
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
    @roles = Role.all.order(:name)
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to roles_path, notice: "Role created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @role.update(role_params)
      redirect_to roles_path, notice: "Role updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @role.users.any?
      redirect_to roles_path, alert: "Cannot delete role with assigned users."
    else
      @role.destroy
      redirect_to roles_path, notice: "Role deleted successfully."
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name)
  end
end
