class Competition < ApplicationRecord
  has_many :groups, dependent: :destroy

  scope :search, ->(val) {
   where("LOWER(competition_name) LIKE :search OR LOWER(country) LIKE :search OR LOWER(location) LIKE :search", search: "%#{val.downcase}%")
 }


  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id competition_name date location country distance_type wre_id ecn]
    column          = allowed_columns.include?(sort_by) ? sort_by : "id"
    direction       = %w[asc desc].include?(direction.to_s.downcase) ? direction : "asc"

    order("#{column} #{direction}")
  }

  scope :country, ->(val) {
    case val.to_s
    when "international" then where.not(country: "Moldova")
    when "all"           then all
    else where(country: val)
    end
  }

  scope :distance_type, ->(val) {
    case val.to_s
    when "all"           then all
    else where(distance_type: val)
    end
  }

  scope :wre, -> { where.not(wre_id: nil) }
  scope :ecn, -> { where(ecn: true) }

  scope :date, ->(from, to) { where date: from..to }
end
