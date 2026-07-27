class GatePassService
  def initialize(job_card, current_user)
    @job_card = job_card
    @current_user = current_user
  end

  def issue!
    year = Date.current.year
    last = JobCard.where("gate_pass_number LIKE ?", "GP-#{year}-%").order(:gate_pass_number).last
    next_num = last ? last.gate_pass_number.split("-").last.to_i + 1 : 1
    gate_pass_number = "GP-#{year}-#{next_num.to_s.rjust(4, '0')}"

    @job_card.update!(
      status: :gate_pass_issued, gate_pass_number: gate_pass_number,
      gate_pass_issued_at: Time.current, gate_pass_issued_by: @current_user,
      delivered_at: Time.current
    )
  end
end
