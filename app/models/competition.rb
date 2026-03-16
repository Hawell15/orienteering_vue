class Competition < ApplicationRecord
  has_many :groups, dependent: :destroy
  before_save :add_checksum

  DISTANCE_TYPES = [ "Sprint", "Medie", "Lungă", "Alegere", "Knock-out Sprint", "Labirint", "Alta" ].freeze

  scope :search, ->(val) {
    sanitized = "%#{sanitize_sql_like(val.to_s.downcase)}%"
    where("LOWER(competition_name) LIKE :search OR LOWER(country) LIKE :search OR LOWER(location) LIKE :search", search: sanitized)
  }

  scope :sorting, ->(sort_by, direction) {
    allowed_columns = %w[id competition_name date location country distance_type wre_id ecn created_at]
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

  scope :wre,  -> { where.not(wre_id: nil) }
  scope :ecn,  -> { where(ecn: true) }
  scope :date, ->(from, to) { where date: from..to }


  def add_checksum
    self.checksum = self.class.get_checksum(competition_name, date, distance_type, wre_id)
  end

  def self.get_checksum(competition_name, date, distance_type, wre_id)
    (Digest::SHA2.new << "#{competition_name}-#{date.as_json}-#{distance_type}-#{wre_id}").to_s
  end

  def self.add_competition(params)
    params = params.with_indifferent_access

    wre_id           = params[:wre_id]
    competition_id   = params[:competition_id]
    competition_name = params[:competition_name]
    date             = params[:date]
    distance_type    = params[:distance_type]

    competition  = Competition.find_by(wre_id: wre_id) if wre_id
    competition ||= Competition.find_by(id: competition_id) if competition_id

    checksum = get_checksum(competition_name, date, distance_type, wre_id)

    competition ||= Competition.find_or_create_by(checksum: checksum) do |comp|
      comp.competition_name = competition_name
      comp.date             = date
      comp.distance_type    = distance_type
      comp.location         = params[:location]
      comp.country          = params[:country]
      comp.wre_id           = wre_id
    end
  end
end
