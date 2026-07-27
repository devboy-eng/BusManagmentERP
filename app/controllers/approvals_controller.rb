class ApprovalsController < ActionController::Base
  layout "approval"

  def show
    @job_card = JobCard.find_by(customer_approval_token: params[:token])
    return render :not_found unless @job_card
    return render :already_approved if @job_card.status_before_type_cast >= 4
    @estimate = @job_card.estimates.last
  end

  def approve
    @job_card = JobCard.find_by(customer_approval_token: params[:token])
    return render :not_found unless @job_card
    @job_card.update!(status: :customer_approved, customer_approved_at: Time.current,
      customer_signature_data: params[:signature_data])
    @job_card.estimates.last&.update!(status: :approved)
    render :thank_you
  end

  def reject
    @job_card = JobCard.find_by(customer_approval_token: params[:token])
    return render :not_found unless @job_card
    @job_card.estimates.last&.update!(status: :rejected)
    render :rejected
  end

  def manager_show
    @job_card = JobCard.find_by(manager_approval_token: params[:token])
    return render :not_found unless @job_card
    @estimate = @job_card.estimates.last
  end

  def manager_approve
    @job_card = JobCard.find_by(manager_approval_token: params[:token])
    return render :not_found unless @job_card
    @job_card.update!(status: :manager_approved, manager_approved_at: Time.current)
    render :thank_you
  end
end
