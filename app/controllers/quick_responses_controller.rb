class QuickResponsesController < ApplicationController
  before_action :set_quick_response, only: [:edit, :update, :destroy]

  def index
    @quick_responses = QuickResponse.order(usage_count: :desc)

    respond_to do |format|
      format.html
      format.json do
        query = params[:q]
        results = if query.present?
                    QuickResponse.by_user(current_user)
                                 .where("shortcode LIKE ? OR title LIKE ? OR body LIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
                                 .order(usage_count: :desc)
                                 .limit(10)
                  else
                    QuickResponse.by_user(current_user).order(usage_count: :desc).limit(10)
                  end
        render json: results.map { |qr| { id: qr.id, title: qr.title, shortcode: qr.shortcode, body: qr.body } }
      end
    end
  end

  def new
    @quick_response = QuickResponse.new
  end

  def create
    @quick_response = QuickResponse.new(quick_response_params)
    @quick_response.user = current_user

    if @quick_response.save
      redirect_to quick_responses_path, notice: "Quick response created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @quick_response.update(quick_response_params)
      redirect_to quick_responses_path, notice: "Quick response updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quick_response.destroy
    redirect_to quick_responses_path, notice: "Quick response deleted.", status: :see_other
  end

  private

  def set_quick_response
    @quick_response = QuickResponse.find(params[:id])
  end

  def quick_response_params
    params.require(:quick_response).permit(:title, :body, :shortcode)
  end
end
