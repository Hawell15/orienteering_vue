class Result < ApplicationRecord
  belongs_to :membership
  belongs_to :category
  belongs_to :group
  has_one :runner, through: :membership

  scope :search, ->(search) {
    where("LOWER(competitions.competition_name) LIKE :search OR LOWER(CONCAT(runners.runner_name, \' \', runners.surname)) LIKE :search OR LOWER(CONCAT(runners.surname, \' \', runners.runner_name)) LIKE :search OR LOWER(clubs.club_name) LIKE :search", search: "%#{search.downcase}%")
  }

  scope :runner, ->(val) {
    case val.to_s
    when "all" then all
    else where("memberships.runner_id": val)
    end
  }

  scope :club, ->(val) {
    case val.to_s
    when "all" then all
    else where("memberships.club_id": val)
    end
  }

  scope :competition, ->(val) {
    case val.to_s
    when "all" then all
    else where("groups.competition_id": val)
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

  scope :wre, -> { where.not(wre_points: nil) }
  scope :ecn, -> { where.not(ecn_points: nil) }
  scope :date, ->(from, to) { where date: from..to }
  scope :status, ->(val) do
    where(status: val)
  end

  scope :with_runner_category_on_date, -> {
    joins(<<~SQL)
    LEFT JOIN LATERAL (
      SELECT r2.category_id
      FROM results r2
      JOIN memberships m2 ON m2.id = r2.membership_id
      JOIN categories c2 ON c2.id = r2.category_id
      WHERE m2.runner_id = runners.id
        AND r2.status = 'confirmed'
        AND r2.date < results.date
        AND r2.date + (c2.validaty_period * INTERVAL '1 year') > results.date
        AND NOT (
          r2.category_id BETWEEN 7 AND 9
          AND (EXTRACT(YEAR FROM results.date) - runners.yob) >= 18
        )
      ORDER BY r2.category_id ASC, r2.date DESC
      LIMIT 1
    ) runner_category_query ON TRUE

    LEFT JOIN categories AS runner_actual_category
      ON runner_actual_category.id = COALESCE(runner_category_query.category_id, 10)
  SQL
  }

 scope :sorting, ->(sort_by, direction) {
  allowed_columns = %w[
    id place full_name club_name runner_category_name time
    result_category_name status date competition_name
    group_name wre_points ecn_points
  ]

  column    = allowed_columns.include?(sort_by) ? sort_by : "date"
  direction = %w[asc desc].include?(direction.to_s.downcase) ? direction : "desc"

  if %w[wre_points ecn_points].include?(column)
    order(Arel.sql("COALESCE(#{column}, -1) #{direction}"))
  else
    order("#{column} #{direction}")
  end
}
end
