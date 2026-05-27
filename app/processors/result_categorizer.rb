class ResultCategorizer
  def initialize(result)
    @result               = result
    @achieved_category_id = nil
    @processed            = false
  end

  def before_save
    return if @result.skip_processing
    return if @result.parent_result_id.present?
    return unless should_reprocess?

    @processed = true
    @result.child_results.destroy_all unless @result.new_record?
    apply_cap
  end

  def after_save
    return if @result.skip_processing
    return if @result.parent_result_id.present?
    return unless @processed

    create_pending_child         if @achieved_category_id
    create_three_results_child   if check_three_results?

    @achieved_category_id = nil
    @processed            = false
  end

  private

  def should_reprocess?
    return true if @result.new_record?
    return true if @result.will_save_change_to_category_id?
    return true if @result.will_save_change_to_status?
    return true if @result.will_save_change_to_date?

    membership_runner_changing?
  end

  def apply_cap
    return unless better_category?

    if needs_pending?
      @achieved_category_id = @result.category_id
      @result.category_id   = [ runner.best_category_id, 4 ].min
      @result.status        = Result::CAPPED
    else
      @result.status = Result::CONFIRMED
    end
  end

  def better_category?
    return false if @result.category_id == Category::NO_CATEGORY_ID
    return true  if @result.group_id == Group::REDUCTION_CATEGORY_GROUP_ID

    runner_category_on_date = runner.category_on_date(@result.date)

    return true unless runner_category_on_date
    return true if @result.category_id <  runner_category_on_date.category_id
    return true if @result.category_id == runner_category_on_date.category_id && @result.date > runner_category_on_date.date

    false
  end

  def needs_pending?
    @result.category_id < 4 && @result.category_id < runner.best_category_id
  end

  def runner
    @result.runner
  end

  def create_pending_child
    Result.create!(
      date:             @result.date,
      category_id:      @achieved_category_id,
      group_id:         Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID,
      membership_id:    @result.membership_id,
      parent_result_id: @result.id,
      status:           Result::PENDING
    )
  end

  def check_three_results?
    return false if @result.category_id == Category::NO_CATEGORY_ID
    return false if @result.date < "2024-03-25".to_date
    return false unless runner.junior_runner?(@result.date)

    runner_category_on_date = runner.category_on_date(@result.date)
    return false if runner_category_on_date && runner_category_on_date.category_id < 9

    runner.results.where(date: "2024-03-25".to_date..@result.date).count >= 3
  end

  def create_three_results_child
    Result.create!(
      date:             @result.date,
      category_id:      9,
      group_id:         Group::THREE_RESULTS_GROUP_ID,
      membership_id:    @result.membership_id,
      parent_result_id: @result.id,
      status:           Result::CONFIRMED
    )
  end

  def membership_runner_changing?
    return false unless @result.will_save_change_to_membership_id?

    old_runner_id = Membership.find_by(id: @result.membership_id_was)&.runner_id
    old_runner_id != @result.membership&.runner_id
  end
end
