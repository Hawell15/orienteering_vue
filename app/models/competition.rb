class Competition < ApplicationRecord
  has_many :groups, dependent: :destroy

  scope :search, ->(search) { where("LOWER(competition_name) LIKE :search OR LOWER(country) LIKE :search OR LOWER(location) LIKE :search", search: "%#{search.downcase}%") }

  scope :sorting, ->(sort_by, direction) { order("#{sort_by} #{direction}") }
  scope :country, lambda { |val|
    case val.to_s
    when "international" then where.not(country: "Moldova")
    when "all"           then all
    else where(country: val.to_s)
    end
  }
  scope :distance_type, lambda { |val|
    case val.to_s
    when "all"           then all
    else where(distance_type: val.to_s)
    end
  }

  scope :wre, -> { where.not(wre_id: nil) }

  scope :date, ->(from, to) { where date: from..to }
end
