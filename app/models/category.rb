class Category < ApplicationRecord
  has_many :runners

  scope :sorting, ->(sort_by, direction) do
    allowed_columns = %w[id category_name points validaty_period]
    column          = allowed_columns.include?(sort_by) ? sort_by : "id"
    direction       = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"

    order("#{column} #{direction}")
  end

  scope :search, ->(search) { where("LOWER(category_name) LIKE :search OR LOWER(full_name) LIKE :search", search: "%#{search.downcase}%") }

   scope :age, ->(val) {
    case val.to_s.downcase
    when "senior"  then where(id: (1..6).to_a + [ 10 ])
    when "junior"  then where(id: (7..10).to_a)
    else all
    end
  }

  scope :points, ->(from, to) do
    where points: from.to_i..to.to_i
  end

  scope :validaty_period, ->(from, to) do
    where validaty_period: from.to_i..to.to_i
  end

  scope :runners_count, ->(from, to) do
    having("COUNT(runners.id) BETWEEN ? AND ?", from.to_i, to.to_i)
  end
end
