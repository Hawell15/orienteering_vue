class Category < ApplicationRecord
  has_many :runners

  scope :sorting, ->(sort_by, direction) do
    dir = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"
    order("#{sort_by} #{dir}")
  end

  scope :search, ->(search) { where("LOWER(category_name) LIKE :search OR LOWER(full_name) LIKE :search", search: "%#{search.downcase}%") }

   scope :age, lambda { |val|
    case val.to_s.downcase
    when "senior"  then where(id: (1..6).to_a + [ 10 ])
    when "junior"  then where(id: (7..10).to_a)
    else all
    end
  }

  scope :points, ->(from, to) do
    where points: from..to
  end

  scope :validaty_period, ->(from, to) do
    where validaty_period: from..to
  end

  scope :runners_count, ->(from, to) do
    scope = left_joins(:runners)
            .group("categories.id")

    if from.present? && to.present?
      scope.having("COUNT(runners.id) BETWEEN ? AND ?", from, to)
    elsif from.present?
      scope.having("COUNT(runners.id) >= ?", from)
    elsif to.present?
      scope.having("COUNT(runners.id) <= ?", to)
    else
      scope
    end
  end
end
