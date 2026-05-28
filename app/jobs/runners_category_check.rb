class RunnersCategoryCheck < ApplicationJob
  queue_as :default

  NEVER             = Date.new(2100, 1, 1).freeze
  JUNIOR_ONLY_RANGE = (7..9).freeze

  def perform
    today = Date.today

    Runner.find_each do |runner|
      desired_id, desired_valid = correct_category_for(runner, today)

      next if runner.category_id == desired_id && runner.category_valid == desired_valid

      runner.update!(category_id: desired_id, category_valid: desired_valid)
    end
  end

  private

  def correct_category_for(runner, today)
    earned = runner.results
                   .where(status: Result::CONFIRMED)
                   .where.not(category_id: Category::NO_CATEGORY_ID)
                   .group(:category_id)
                   .maximum(:date)
                   .sort

    junior     = runner.junior_runner?(today)
    best_id    = Category::NO_CATEGORY_ID
    best_valid = NEVER

    earned.each do |start_id, earned_on|
      break if start_id >= best_id
      next  if junior_only?(start_id) && !junior

      sim_id, sim_valid = walk_ladder(start_id, earned_on, today, junior: junior)
      next unless sim_id < best_id

      best_id    = sim_id
      best_valid = sim_valid
    end

    [ best_id, best_valid ]
  end

  # Annex 1 §3.4: lapsed period demotes by one step. Walks from
  # start_id forward through the ladder, accumulating validity onto
  # earned_on, until something is still valid at today (or the ladder
  # ends). Adult runners cannot land on junior-only ranks (7–9) — those
  # steps short-circuit to NO_CATEGORY.
  def walk_ladder(start_id, earned_on, today, junior:)
    id     = start_id
    expiry = earned_on

    while id < Category::NO_CATEGORY_ID
      return [ Category::NO_CATEGORY_ID, NEVER ] if junior_only?(id) && !junior

      expiry += category_validity.fetch(id).years
      return [ id, expiry ] if expiry > today

      id += 1
    end

    [ Category::NO_CATEGORY_ID, NEVER ]
  end

  def junior_only?(category_id)
    JUNIOR_ONLY_RANGE.cover?(category_id)
  end

  def category_validity
    @category_validity ||= Category.pluck(:id, :validaty_period).to_h
  end
end
