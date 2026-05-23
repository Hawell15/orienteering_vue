class ResultProcessor
  attr_accessor :params, :result, :runner

  def initialize(params = nil, result = nil)
    @params = params.with_indifferent_access
    @params["category_id"] = @params["category_id"].to_i if @params["category_id"].present?
    @params["group_id"]    = @params["group_id"].to_i    if @params["group_id"].present?
    @result = result
    @runner = Runner.find(params[:runner_id])
  end

  def add_result
    return handle_update_result if result

    params["membership_id"] = add_membership_id

    check_params = { membership_id: params["membership_id"], group_id: params["group_id"] }
    check_params.merge!(date: params["date"]) if params["date"]

    @result = Result.find_by(check_params)
    params["status"] ||= Result::UNCONFIRMED

    if result
      return handle_update_result
    end

    pending_category = apply_pending_cap_if_needed

    @result = Result.create!(params.except("runner_id", "membership"))

    create_pending_result(pending_category) if pending_category
    add_tree_results_category
  end

  def update_result
    handle_update_result
  end

  private

  def better_category?
    category_id = current_category_id
    return false if category_id == Category::NO_CATEGORY_ID
    return true  if current_group_id == Group::REDUCTION_CATEGORY_GROUP_ID

    date = current_date
    runner_category_on_date = runner.category_on_date(date)

    return true unless runner_category_on_date
    return true if category_id <  runner_category_on_date.category_id
    return true if category_id == runner_category_on_date.category_id && date > runner_category_on_date.date

    false
  end

  def apply_pending_cap_if_needed
    return nil unless better_category?

    if needs_pending?
      achieved = params["category_id"]
      params["category_id"] = [ runner.best_category_id, 4 ].min
      params["status"]      = Result::CAPPED
      achieved
    else
      params["status"] = Result::CONFIRMED
      nil
    end
  end

  def needs_pending?
    params["category_id"] < 4 && params["category_id"] < runner.best_category_id
  end

  def create_pending_result(achieved_category)
    Result.create!(
      date:             current_date,
      category_id:      achieved_category,
      group_id:         Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID,
      membership_id:    result.membership_id,
      parent_result_id: result.id,
      status:           Result::PENDING
    )
  end

  def add_tree_results_category
    return unless check_three_results?

    Result.create!(
      date:             current_date,
      category_id:      9,
      group_id:         Group::THREE_RESULTS_GROUP_ID,
      membership_id:    result.membership_id,
      parent_result_id: result.id,
      status:           Result::CONFIRMED
    )
  end

  def handle_update_result
    category_changed = params["category_id"].present? && result.category_id != params["category_id"]
    status_changed   = params["status"].present?      && result.status      != params["status"]
    return unless category_changed || status_changed

    pending_category = category_changed ? apply_pending_cap_if_needed : nil

    if category_changed
      result.child_results.destroy_all
    end

    result.update!(params.slice("category_id", "status"))

    if category_changed
      create_pending_result(pending_category) if pending_category
      add_tree_results_category
    end
  end

  def check_three_results?
    date = current_date
    return false if current_category_id == Category::NO_CATEGORY_ID
    return false if date < "2024-03-25".to_date
    return false unless runner.junior_runner?(date)

    runner_category_on_date = runner.category_on_date(date)

    return false if runner_category_on_date && runner_category_on_date.category_id < 9

    results = runner.results.where(date: "2024-03-25".to_date..date)

    return false if results.count < 3

    true
  end

  def current_date
    params["date"]&.to_date || result&.date
  end

  def current_category_id
    params["category_id"] || result&.category_id
  end

  def current_group_id
    params["group_id"] || result&.group_id
  end

  def add_membership_id
    club_id = Club.add_club(club_name: @params[:membership]).id

    Membership.add_membership(runner_id: @params[:runner_id], club_id: club_id).id
  end
end
