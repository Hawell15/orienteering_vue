# frozen_string_literal: true

json.extract! category, :id, :category_name, :full_name, :points, :validaty_period, :created_at, :updated_at
json.url category_url(category, format: :json)
