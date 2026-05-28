class GroupPlaceReorderer
  def initialize(group)
    @group = group
  end

  def call
    Result.transaction do
      timed_results.each_with_index do |result, idx|
        new_place = idx + 1
        result.update_column(:place, new_place) if result.place != new_place
      end

      untimed_results.each do |result|
        result.update_column(:place, nil) unless result.place.nil?
      end
    end
  end

  private

  def base_scope
    @group.results.where(parent_result_id: nil)
  end

  def timed_results
    base_scope.where.not(time: [ nil, 0 ]).order(:time)
  end

  def untimed_results
    base_scope.where(time: [ nil, 0 ])
  end
end
