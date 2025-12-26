class Club < ApplicationRecord
  has_many :runners

  scope :search, ->(search) { where("LOWER(club_name) LIKE :search OR LOWER(territory) LIKE :search OR LOWER(representative) LIKE :search OR LOWER(email) LIKE :search OR LOWER(phone) LIKE :search", search: "%#{search.downcase}%") }

  scope :sorting, ->(sort_by, direction) { order("#{sort_by} #{direction}") }

  scope :runners_count, ->(from, to) do
    scope = left_joins(:runners)
            .group("club.id")

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
