class Club < ApplicationRecord
  DEFAULT_CLUB_ID = 1

  has_many :runners
  has_many :memberships

  before_destroy :set_default_club

  before_validation :add_formatted_name, if: :will_save_change_to_club_name?
  before_validation :add_formatted_alternative_names

  scope :search, ->(val) {
    where("LOWER(club_name) LIKE :search OR LOWER(territory) LIKE :search OR LOWER(representative) LIKE :search OR LOWER(email) LIKE :search OR LOWER(phone) LIKE :search", search: "%#{val.downcase}%")
  }

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id club_name territory representative email phone created_at]

    column = allowed_columns.include?(sort_by) ? sort_by : "id"
    dir    = %w[asc desc].include?(direction&.downcase) ? direction : "asc"

    order(column => dir)
  }

  scope :runners_count, ->(from, to) {
    having("COUNT(memberships.id) BETWEEN ? AND ?", from.to_i, to.to_i)
  }

   def self.add_club(params)
    params = params.with_indifferent_access

    formatted_name = format_name(params[:club_name])
    return find(DEFAULT_CLUB_ID) if formatted_name.blank?

    club = find_by(formatted_name: formatted_name) ||
           where("? = ANY(alternative_club_names)", formatted_name).first ||
           create!(params)
  end

  def self.format_name(name)
    return if name.blank?

    RussianConversion.convert_from_russian(name.downcase)
      .gsub("k", "c")
      .gsub("ș", "s")
      .gsub("ț", "t")
      .gsub("ă", "a")
      .gsub("î", "i")
      .gsub("â", "i")
      .gsub(/[^a-z]+/, "")
  end

  # Merge another club into this one.
  # Moves runners and memberships, merges alternative_club_names, and destroys the other club.
  def merge_from!(other_club)
    raise ArgumentError, "Cannot merge a club into itself" if other_club.id == id

    transaction do
      formatted_merged_name = self.class.format_name(other_club.club_name)

      combined_alternatives = alternative_club_names | other_club.alternative_club_names | [ formatted_merged_name ]

      update!(alternative_club_names: combined_alternatives)

      Runner.where(club_id: other_club.id).update_all(club_id: id)

      Membership.where(club_id: other_club.id).update_all(club_id: id)

      other_club.destroy!
    end
  end

  private

  def add_formatted_name
    self.formatted_name = self.class.format_name(club_name)
  end

  def add_formatted_alternative_names
    return if alternative_club_names.blank?

    self.alternative_club_names =
      alternative_club_names
        .map(&:strip)
        .map { |name| self.class.format_name(name) }
        .compact
        .uniq
  end

  def set_default_club
    memberships.update_all(club_id: DEFAULT_CLUB_ID)

    runners.includes(:memberships, :results).find_each do |runner|
      other_memberships = runner.memberships.where.not(club_id: club_id)

      unless other_memberships.exists?
        runner.update!(club_id: DEFAULT_CLUB_ID)
        next
      end

      next
    end

    new_club_id =
      runner.results
            .where(membership_id: other_memberships.select(:id))
            .order(date: :desc)
            .joins(:membership)
            .limit(1)
            .pick("memberships.club_id")

    new_club_id ||= other_memberships
                      .order(created_at: :desc)
                      .limit(1)
                      .pick(:club_id)

    runner.update!(club_id: new_club_id)
    end
end
