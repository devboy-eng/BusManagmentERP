class FeedbackController < ActionController::Base
  skip_forgery_protection

  layout "feedback"

  def show
    @csat_response = CsatResponse.find_by(token: params[:token])

    if @csat_response.nil?
      render :not_found, status: :not_found
    elsif @csat_response.submitted?
      render :thank_you
    end
  end

  def submit
    @csat_response = CsatResponse.find_by(token: params[:token])

    if @csat_response.nil?
      render :not_found, status: :not_found
      return
    end

    if @csat_response.submitted?
      render :thank_you
      return
    end

    @csat_response.assign_attributes(feedback_params)
    @csat_response.submitted_at = Time.current

    if @csat_response.save(context: :submit)
      render :thank_you
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:csat_response).permit(:service_rating, :support_rating, :would_recommend, :improvement_suggestion, :additional_comments)
  end
end
