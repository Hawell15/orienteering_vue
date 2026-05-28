class ExpiredCategoryJob < ApplicationJob
  queue_as :default

  def perform(*args)
    runners = Runner.where("category_valid < ?", Date.today).to_a

    runners.each do |runner|
      current_category = runner.category_id
      next if current_category == Category::NO_CATEGORY_ID

      category_id =  current_category == 6 && !runner.junior_runner? ? Category::NO_CATEGORY_ID : current_category + 1
      next if category_id == Category::NO_CATEGORY_ID

      ResultProcessor.new({ runner_id: runner.id, membership: runner.club.club_name, category_id: category_id, date: runner.category_valid, group_id: Group::REDUCTION_CATEGORY_GROUP_ID }).add_result
    end

    runners.each(&:update_runner_category)
  end
end
