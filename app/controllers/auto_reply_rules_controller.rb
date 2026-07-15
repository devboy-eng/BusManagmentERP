class AutoReplyRulesController < ApplicationController
  before_action :set_rule, only: [:edit, :update, :destroy, :toggle]

  def index
    @rules = AutoReplyRule.order(created_at: :desc)
  end

  def new
    @rule = AutoReplyRule.new
  end

  def create
    @rule = AutoReplyRule.new(rule_params)
    @rule.user = current_user

    if @rule.save
      redirect_to auto_reply_rules_path, notice: "Auto-reply rule created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @rule.update(rule_params)
      redirect_to auto_reply_rules_path, notice: "Auto-reply rule updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.destroy
    redirect_to auto_reply_rules_path, notice: "Auto-reply rule deleted.", status: :see_other
  end

  def toggle
    @rule.update!(active: !@rule.active?)
    redirect_to auto_reply_rules_path, notice: "Rule #{@rule.active? ? 'activated' : 'deactivated'}.", status: :see_other
  end

  private

  def set_rule
    @rule = AutoReplyRule.find(params[:id])
  end

  def rule_params
    params.require(:auto_reply_rule).permit(:name, :trigger_type, :keyword, :reply_body, :active)
  end
end
