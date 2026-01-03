class Runner < ApplicationRecord
  belongs_to :club
  belongs_to :category
  belongs_to :best_category, class_name: "Category"
  has_many :memberships, dependent: :destroy
  has_many :results, through: :memberships

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[
      id full_name category_id category_valid gender yob club_name best_category_id wre_id sprint_wre_place forest_wre_place
    ]

    column    = allowed_columns.include?(sort_by) ? sort_by : "date"
    direction = %w[asc desc].include?(direction.to_s.downcase) ? direction : "desc"
    order("#{column} #{direction}")
  }

  scope :club, ->(val) {
    case val.to_s
    when "all" then all
    else where(club_id: val)
    end
  }

  scope :membership, ->(val) {
    case val.to_s
    when "all" then all
    else joins(:memberships).where("memberships.club_id": val)
    end
  }

  scope :category, ->(val) {
    case val.to_s
    when "all" then all
    else where(category_id: val)
    end
  }

  scope :best_category, ->(val) {
    case val.to_s
    when "all" then all
    else where(best_category: val)
    end
  }

  scope :gender, ->(val) {
    case val.to_s
    when "all" then all
    else where(gender: val)
    end
  }

  scope :wre, -> { where.not(wre_id: nil) }
  scope :yob, ->(from, to) { where yob: from..to }
end
