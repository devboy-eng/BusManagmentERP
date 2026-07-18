class CsatController < ApplicationController
  include Pagy::Backend

  def index
    @overall_score = Rails.cache.fetch("csat/overall_score", expires_in: 10.minutes) { CsatResponse.overall_csat_score }
    @avg_service = Rails.cache.fetch("csat/avg_service", expires_in: 10.minutes) { CsatResponse.average_service_rating }
    @avg_support = Rails.cache.fetch("csat/avg_support", expires_in: 10.minutes) { CsatResponse.average_support_rating }
    @recommendation_rate = Rails.cache.fetch("csat/recommendation_rate", expires_in: 10.minutes) { CsatResponse.recommendation_rate }
    @total_responses = Rails.cache.fetch("csat/total_responses", expires_in: 10.minutes) { CsatResponse.submitted.count }

    # Rating distributions
    @service_distribution = Rails.cache.fetch("csat/service_distribution", expires_in: 10.minutes) { rating_distribution(:service_rating) }
    @support_distribution = Rails.cache.fetch("csat/support_distribution", expires_in: 10.minutes) { rating_distribution(:support_rating) }

    # Agent-wise scores
    @agent_stats = Rails.cache.fetch("csat/agent_stats", expires_in: 10.minutes) do
      User.joins(:csat_responses)
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
          .to_a
    end

    # Recent responses (paginated) — NOT cached (varies by page)
    @pagy, @recent_responses = pagy(
      CsatResponse.submitted
                  .includes(:respondent, :user)
                  .order(submitted_at: :desc),
      items: 10
    )

    # For generate link form — NOT cached (need current data)
    @customers = Customer.order(:name)
    @leads = Lead.order(:name)
    @users = User.active.order(:name)
  end

  def agent
    @agent = User.find(params[:id])
    @responses = CsatResponse.submitted.where(user: @agent)

    agent_cache_key = "csat/agent/#{@agent.id}"
    cached_stats = Rails.cache.fetch("#{agent_cache_key}/stats", expires_in: 10.minutes) do
      avg_service = @responses.average(:service_rating)&.round(1) || 0
      avg_support = @responses.average(:support_rating)&.round(1) || 0
      overall = (avg_service.to_f + avg_support.to_f) / 2.0
      overall = overall.zero? ? 0 : overall.round(1)
      total = @responses.count
      rec_rate = total.zero? ? 0 : (@responses.where(would_recommend: true).count.to_f / total * 100).round(1)

      {
        avg_service: avg_service,
        avg_support: avg_support,
        overall_score: overall,
        recommendation_rate: rec_rate,
        total_responses: total
      }
    end

    @avg_service = cached_stats[:avg_service]
    @avg_support = cached_stats[:avg_support]
    @overall_score = cached_stats[:overall_score]
    @recommendation_rate = cached_stats[:recommendation_rate]
    @total_responses = cached_stats[:total_responses]

    @service_distribution = Rails.cache.fetch("#{agent_cache_key}/service_distribution", expires_in: 10.minutes) { rating_distribution(:service_rating, @responses) }
    @support_distribution = Rails.cache.fetch("#{agent_cache_key}/support_distribution", expires_in: 10.minutes) { rating_distribution(:support_rating, @responses) }

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
