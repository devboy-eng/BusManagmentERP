class WhatsappTemplatesController < ApplicationController
  before_action :set_template, only: [:edit, :update, :destroy]

  def index
    @templates = WhatsappTemplate.ordered
  end

  def new
    @template = WhatsappTemplate.new(language: "en", header_type: "none")
  end

  def create
    @template = current_user.whatsapp_templates.build(template_params)
    if @template.save
      redirect_to whatsapp_templates_path, notice: "Template created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to whatsapp_templates_path, notice: "Template updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to whatsapp_templates_path, notice: "Template deleted successfully."
  end

  private

  def set_template
    @template = WhatsappTemplate.find(params[:id])
  end

  def template_params
    params.require(:whatsapp_template).permit(:name, :body, :category, :language, :header_type, :header_text, :header_media_url, :footer)
  end
end
