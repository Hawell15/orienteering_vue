class Club < ApplicationRecord
  has_many :runners
  has_many :memberships

  scope :search, ->(search) {
    where("LOWER(club_name) LIKE :search OR LOWER(territory) LIKE :search OR LOWER(representative) LIKE :search OR LOWER(email) LIKE :search OR LOWER(phone) LIKE :search", search: "%#{search.downcase}%")
  }

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id club_name territory representative email phone]
    column          = allowed_columns.include?(sort_by) ? sort_by : "id"
    direction       = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"

    order("#{column} #{direction}")
  }

  scope :runners_count, ->(from, to) {
    having("COUNT(memberships.id) BETWEEN ? AND ?", from.to_i, to.to_i)
  }
end
