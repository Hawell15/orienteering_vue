class Category < ApplicationRecord
  has_many :runners
  has_many :results

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id category_name points validaty_period runners_count]
    column          = allowed_columns.include?(sort_by) ? sort_by : "id"
    direction       = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"

    order("#{column} #{direction}")
  }

  scope :search, ->(val) {
    where("LOWER(category_name) LIKE :search OR LOWER(full_name) LIKE :search", search: "%#{val.downcase}%")
  }

  scope :age, ->(val) {
    case val.to_s.downcase
    when "senior"  then where(id: (1..6).to_a + [ 10 ])
    when "junior"  then where(id: (7..10).to_a)
    else all
    end
  }

  scope :points,          ->(from, to) { where points: from.to_i..to.to_i }
  scope :validaty_period, ->(from, to) { where validaty_period: from.to_i..to.to_i }
  scope :runners_count,   ->(from, to) { having("COUNT(runners.id) BETWEEN ? AND ?", from.to_i, to.to_i) }
end
