class RelayResultsController < ApplicationController
  before_action :set_relay_result, only: %i[show update destroy]
  before_action :require_admin!,   only: %i[create update destroy]

  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :competition
  has_scope :group_data
  has_scope :category
  has_scope :date, using: %i[from to], type: :hash

  def index
    relays = apply_scopes(index_base_query).to_a
    legs   = legs_lookup_for(relays)

    render json: relays.map { |r| serialize(r, legs) }
  end

  def show
    relays = [ @relay_result ]
    legs   = legs_lookup_for(relays)
    render json: serialize(@relay_result, legs)
  end

  def create
    @relay_result = RelayResult.new(relay_result_params)

    if @relay_result.save
      render json: serialize(@relay_result, legs_lookup_for([ @relay_result ])), status: :ok
    else
      render json: @relay_result.errors, status: :unprocessable_content
    end
  end

  def update
    if @relay_result.update(relay_result_params)
      render json: serialize(@relay_result, legs_lookup_for([ @relay_result ])), status: :ok
    else
      render json: @relay_result.errors, status: :unprocessable_content
    end
  end

  def destroy
    @relay_result.destroy!
    head :no_content
  end

  private

  def set_relay_result
    @relay_result = RelayResult.find(params.expect(:id))
  end

  def relay_result_params
    params.expect(relay_result: [ :place, :time, :team, :date, :category_id, :group_id, { results_id: [] } ])
  end

  def index_base_query
    RelayResult
      .left_joins(:category, group: :competition)
      .select(<<~SQL)
        relay_results.*,
        categories.category_name AS category_name,
        groups.group_name AS group_name,
        groups.rang AS group_rang,
        groups.clasa AS group_clasa,
        groups.competition_id AS competition_id,
        competitions.competition_name AS competition_name
      SQL
      .order(:group_id, :place)
  end

  def legs_lookup_for(relays)
    ids = relays.flat_map { |r| r.results_id || [] }.compact.uniq
    return {} if ids.empty?

    Result
      .where(id: ids)
      .joins(membership: :runner)
      .left_joins(:category)
      .with_runner_category_on_date
      .select(<<~SQL)
        results.*,
        CONCAT(runners.runner_name, ' ', runners.surname) AS full_name,
        runners.id AS runner_id,
        categories.category_name AS leg_category_name,
        runner_actual_category.category_name AS runner_category_name
      SQL
      .index_by(&:id)
  end

  def serialize(relay, legs)
    {
      id:               relay.id,
      place:            relay.place,
      team:             relay.team,
      time:             relay.time,
      date:             relay.date,
      group_id:         relay.group_id,
      category_id:      relay.category_id,
      results_id:       relay.results_id,
      category_name:    relay.try(:category_name)    || relay.category&.category_name,
      group_name:       relay.try(:group_name)       || relay.group&.group_name,
      group_rang:       relay.try(:group_rang)       || relay.group&.rang,
      group_clasa:      relay.try(:group_clasa)      || relay.group&.clasa,
      competition_id:   relay.try(:competition_id)   || relay.group&.competition_id,
      competition_name: relay.try(:competition_name) || relay.group&.competition&.competition_name,
      legs:             (relay.results_id || []).filter_map { |id| serialize_leg(legs[id]) }
    }
  end

  def serialize_leg(leg)
    return unless leg

    {
      id:                   leg.id,
      place:                leg.place,
      time:                 leg.time,
      runner_id:            leg.try(:runner_id),
      full_name:            leg.try(:full_name),
      leg_category_name:    leg.try(:leg_category_name),
      runner_category_name: leg.try(:runner_category_name)
    }
  end
end
