class ExpiredCategoryJob < ApplicationJob
  queue_as :default

  def perform(*args)
    runners = Runner.where("category_valid < ?", Date.today).to_a
    old_category_ids = runners.each_with_object({}) { |r, h| h[r.id] = r.category_id }

    runners.each do |runner|
      current_category = runner.category_id
      next if current_category == Category::NO_CATEGORY_ID

      category_id =  current_category == 6 && !runner.junior_runner? ? Category::NO_CATEGORY_ID : current_category + 1
      next if category_id == Category::NO_CATEGORY_ID

      ResultProcessor.new({ runner_id: runner.id, membership: runner.club.club_name, category_id: category_id, date: runner.category_valid + 1.day, group_id: Group::REDUCTION_CATEGORY_GROUP_ID }).add_result
    end

    # Reduction results are dated `category_valid + 1.day` — i.e. today at the
    # earliest. `category_on_date` uses strict `<`, so a date of today would
    # miss them. Look ahead by one day so the freshly-created reduction is
    # found and the runner's effective category updates immediately.
    runners.each { |runner| runner.update_runner_category(Date.tomorrow) }

    notify_telegram(changes_from(runners, old_category_ids))
  end

  private

  def changes_from(runners, old_category_ids)
    runners.filter_map do |runner|
      runner.reload
      old_id = old_category_ids[runner.id]
      next if runner.category_id == old_id

      { runner: runner, old_category_id: old_id, new_category_id: runner.category_id }
    end
  end

  def notify_telegram(changes)
    return if changes.empty?

    TelegramExpiredCategoryNotifier.notify(changes)
  rescue => e
    Rails.logger.error("ExpiredCategoryJob: Telegram notification failed: #{e.class}: #{e.message}")
  end
end
