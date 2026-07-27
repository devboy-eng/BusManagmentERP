class BranchesController < ApplicationController
  before_action :set_branch, only: [:edit, :update, :destroy]

  def index
    @branches = Branch.all.order(:name)
    @pagy, @branches = pagy(@branches, items: 15)
  end

  def new
    @branch = Branch.new
  end

  def create
    @branch = Branch.new(branch_params)
    if @branch.save
      redirect_to branches_path, notice: "Branch created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @branch.update(branch_params)
      redirect_to branches_path, notice: "Branch updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @branch.destroy
    redirect_to branches_path, notice: "Branch deleted."
  end

  private

  def set_branch
    @branch = Branch.find(params[:id])
  end

  def branch_params
    params.require(:branch).permit(:name, :code, :address, :city, :state, :state_code,
      :phone, :email, :gst_number, :is_default, :active)
  end
end
