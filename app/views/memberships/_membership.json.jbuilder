json.extract! membership, :id, :runner_id, :club_id, :main, :created_at, :updated_at
json.club_name membership.try(:club_name)
json.club_id membership.try(:club_id)
json.runners_id membership.try(:runners_id)
json.full_name membership.try(:full_name)
json.results_count membership.try(:results_count)
json.url membership_url(membership, format: :json)
