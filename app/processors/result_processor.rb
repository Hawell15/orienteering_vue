class ResultProcessor
  attr_accessor :params, :result, :runner

  def initialize(params = nil, result = nil)
    @params = params.with_indifferent_access
   @params["category_id"] = @params["category_id"].to_i if @params["category_id"].present?
    @params["group_id"]   = @params["group_id"].to_i    if @params["group_id"].present?
    @result = result
    @runner = Runner.find(params[:runner_id])
  end

  def add_result
    params["membership_id"] = add_membership_id

    check_params = { membership_id: params["membership_id"], group_id: params["group_id"] }
    check_params.merge!(date: params["date"]) if params["date"]

    result = Result.find_by(check_params)

    return result if result

    @result = Result.create!(params.except("runner_id", "membership"))

    @result
  end

  def update_result
    attrs = params.slice("category_id", "status").compact
    return result if attrs.empty?
    return result if attrs.all? { |k, v| result.public_send(k) == v }

    result.update!(attrs)
    result
  end

  private

  def add_membership_id
    club_id = Club.add_club(club_name: params[:membership]).id

    Membership.add_membership(runner_id: params[:runner_id], club_id: club_id).id
  end
end
