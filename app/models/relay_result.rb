class RelayResult < ApplicationRecord
  EXPECTED_LEG_COUNTS = {
    "Ștafetă clasică" => 3,
    "Ștafetă sprint"  => 4
  }.freeze

  belongs_to :group
  belongs_to :category

  validate :leg_count_matches_relay_type
  validate :legs_in_same_group

  scope :competition, ->(val) {
    case val.to_s
    when "all" then all
    else joins(:group).where("groups.competition_id": val)
    end
  }

  scope :group_data, ->(val) {
    case val.to_s
    when "all" then all
    else where(group_id: val)
    end
  }

  scope :category, ->(val) {
    case val.to_s
    when "all" then all
    else where(category_id: val)
    end
  }

  scope :date, ->(from, to) { where date: from..to }

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id place time team date created_at]
    column          = allowed_columns.include?(sort_by) ? sort_by : "place"
    direction       = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"
    order("#{column} #{direction}")
  }

  def expected_leg_count
    EXPECTED_LEG_COUNTS[group&.competition&.distance_type]
  end

  private

  def leg_count_matches_relay_type
    expected = expected_leg_count
    return unless expected

    actual = (results_id || []).size
    return if actual == expected

    errors.add(:results_id, "trebuie să conțină #{expected} sportivi pentru #{group.competition.distance_type}")
  end

  def legs_in_same_group
    return if (results_id || []).empty?
    return if group_id.blank?

    foreign = Result.where(id: results_id).where.not(group_id: group_id).pluck(:id)
    return if foreign.empty?

    errors.add(:results_id, "conține rezultate din alte grupe: #{foreign.join(', ')}")
  end
end
