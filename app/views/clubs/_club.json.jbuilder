json.extract! club, :id, :club_name, :territory, :representative, :email, :phone, :alternative_club_name, :formatted_name, :created_at, :updated_at
json.runners_count club.try(:runners_count)
json.url club_url(club, format: :json)
