class ResultProcessor
  attr_accessor :params, :result, :runner

  def initialize(params = nil, result = nil)
    @params = params.with_indifferent_access
    @result = result
    @runner = Runner.find(params[:runner_id])
  end

  def add_result
    params = @params.with_indifferent_access

    params["membership_id"] =  add_membership_id

    check_params =
      {
        membership_id: params["membership_id"],
        group_id: params["group_id"]
      }

    check_params.merge!(date: params["date"]) if params["date"]

    @result = Result.find_by(check_params)

    params["status"] ||= Result::UNCONFIRMED

    if result
      return handle_update_result
    end

    if better_category?
      create_pending_result

      params["status"] = Result::CONFIRMED
    end

    add_tree_results_category

    @result = Result.create!(params.except("runner_id", "membership"))
  end

  def update_result
    params = @params.with_indifferent_access

    result.update!(params)
    result.entry&.destroy
    add_entry

    result
  end

  private

  def better_category?
    return false if params["category_id"] == Category::NO_CATEGORY_ID
    return true if params["group_id"]     == Group::REDUCTION_CATEGORY_GROUP_ID

    runner_category_on_date = runner.category_on_date(params["date"])

    return true unless runner_category_on_date
    return true if params["category_id"] < runner_category_on_date.category_id
    return true if params["category_id"] == runner_category_on_date.category_id && params["date"].to_date > runner_category_on_date.date

    false
  end

  def create_pending_result
    return unless params["category_id"] < 4
    return unless params["category_id"] < runner.best_category_id

    Result.create!({
      date:          params["date"],
      category_id:   params["category_id"],
      group_id:      Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID,
      membership_id: params["membership_id"],
      status:        Result::PENDING
    }.compact)

    params["category_id"] = [ runner.best_category_id, 4 ].min
  end

  def add_tree_results_category
    return unless check_three_results?

    Result.create!({
      date:          params["date"],
      category_id:   9,
      group_id:      Group::THREE_RESULTS_GROUP_ID,
      membership_id: params["membership_id"],
      status:        Result::CONFIRMED
    }.compact)
  end

  def handle_update_result
    return if result.category_id == params["category_id"]

    if better_category?
      create_pending_result
      params["status"] = Result::CONFIRMED
    end

    result.update!(params.slice("category_id", "status"))
  end

  def check_three_results?
    return false if params["category_id"] == Category::NO_CATEGORY_ID
    return false if params["date"].to_date < "2024-03-25".to_date
    return false unless runner.junior_runner?

    runner_category_on_date = runner.category_on_date(params["date"])

    return false if runner_category_on_date && runner_category_on_date.category_id < 9

    results = runner.results.where(date: "2024-03-25".to_date .. params["date"])

    return false if results.count < 3

    true
  end

  def add_membership_id
    club_id = Club.add_club(club_name: @params[:membership]).id

    Membership.add_membership(runner_id: @params[:runner_id], club_id: club_id).id
  end
end
