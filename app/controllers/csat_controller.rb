class CsatController < ApplicationController
  include Pagy::Backend

  def index
    @overall_score = CsatResponse.overall_csat_score
    @avg_service = CsatResponse.average_service_rating
    @avg_support = CsatResponse.average_support_rating
    @recommendation_rate = CsatResponse.recommendation_rate
    @total_responses = CsatResponse.submitted.count

    # Rating distributions
    @service_distribution = rating_distribution(:service_rating)
    @support_distribution = rating_distribution(:support_rating)

    # Agent-wise scores
    @agent_stats = User.joins(:csat_responses)
                       .merge(CsatResponse.submitted)
                       .select(
                         "users.id",
                         "users.name",
                         "COUNT(csat_responses.id) as response_count",
                         "ROUND(AVG(csat_responses.service_rating), 1) as avg_service",
                         "ROUND(AVG(csat_responses.support_rating), 1) as avg_support",
                         "ROUND((AVG(csat_responses.service_rating) + AVG(csat_responses.support_rating)) / 2.0, 1) as avg_overall"
                       )
                       .group("users.id, users.name")
                       .order("avg_overall DESC")

    # Recent responses (paginated)
    @pagy, @recent_responses = pagy(
      CsatResponse.submitted
                  .includes(:respondent, :user)
                  .order(submitted_at: :desc),
      items: 10
    )

    # For generate link form
    @customers = Customer.order(:name)
    @leads = Lead.order(:name)
    @users = User.active.order(:name)
  end

  def agent
    @agent = User.find(params[:id])
    @responses = CsatResponse.submitted.where(user: @agent)

    @avg_service = @responses.average(:service_rating)&.round(1) || 0
    @avg_support = @responses.average(:support_rating)&.round(1) || 0
    @overall_score = (@avg_service.to_f + @avg_support.to_f) / 2.0
    @overall_score = @overall_score.zero? ? 0 : @overall_score.round(1)
    @recommendation_rate = begin
      total = @responses.count
      total.zero? ? 0 : (@responses.where(would_recommend: true).count.to_f / total * 100).round(1)
    end
    @total_responses = @responses.count

    @service_distribution = rating_distribution(:service_rating, @responses)
    @support_distribution = rating_distribution(:support_rating, @responses)

    @pagy, @agent_responses = pagy(
      @responses.includes(:respondent).order(submitted_at: :desc),
      items: 10
    )
  end

  def generate_link
    respondent = if params[:respondent_type] == "Customer"
      Customer.find_by(id: params[:respondent_id])
    elsif params[:respondent_type] == "Lead"
      Lead.find_by(id: params[:respondent_id])
    end

    agent = User.find_by(id: params[:user_id]) || respondent&.user

    csat = CsatResponse.create!(
      respondent: respondent,
      user: agent
    )

    redirect_to csat_index_path, notice: "Feedback link generated: #{feedback_url(token: csat.token)}"
  end

  private

  def rating_distribution(field, scope = CsatResponse.submitted)
    total = scope.count
    return {} if total.zero?

    counts = scope.group(field).count
    (1..5).each_with_object({}) do |rating, hash|
      count = counts[rating] || 0
      hash[rating] = { count: count, percentage: (count.to_f / total * 100).round(1) }
    end
  end
end
