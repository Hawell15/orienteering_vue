json.extract! group, :id, :group_name, :rang, :clasa, :ecn_coeficient, :competition_id, :created_at, :updated_at
json.competition_name group.try(:competition_name)
json.date group.try(:date)
json.clasa_name group.try(:clasa_name)
json.results_count group.try(:results_count)

json.url group_url(group, format: :json)
