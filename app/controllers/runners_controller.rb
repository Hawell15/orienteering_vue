class RunnersController < ApplicationController
  before_action :set_runner, only: %i[ show edit update destroy merge_runners relays]
  before_action :require_admin!, only: %i[new create edit update destroy merge_runners category_check bulk_update_license]
  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :search
  has_scope :club
  has_scope :membership
  has_scope :category
  has_scope :best_category
  has_scope :gender
  has_scope :wre, type: :boolean
  has_scope :license
  has_scope :yob, using: %i[from to], type: :hash

  # GET /runners or /runners.json
  def index
    respond_to do |format|
      format.html # renders index.html.erb
      format.json { render json: apply_scopes(index_base_query) }
    end
  end

  # GET /runners/1 or /runners/1.json
  def show
    respond_to do |format|
      format.html # renders index.html.erb
      format.json { render json:
        @runner.as_json(
          include: [ category: {}, club: {}, best_category: {} ]
        ) }
    end
  end

  # GET /runners/new
  def new
    @runner = Runner.new
  end

  # GET /runners/1/edit
  def edit
  end

  # POST /runners or /runners.json
  def create
    @runner = Runner.new(runner_params)

    respond_to do |format|
      if @runner.save
        format.json { render json: index_base_query.find(@runner.id), status: :ok }
      else
        format.json { render json: @runner.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /runners/1 or /runners/1.json
  def update
    respond_to do |format|
      if @runner.update(runner_params)
        format.json { render json: index_base_query.find(@runner.id), status: :ok }
      else
        format.json { render json: @runner.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /runners/1 or /runners/1.json
  def destroy
    @runner.destroy!

    respond_to do |format|
      format.html { redirect_to runners_path, notice: "Runner was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def filters
    render json:
      {
        clubs:      Club.select(:id, :club_name).order(:club_name).as_json,
        categories: Category.select(:id, :category_name).order(:id).as_json,
        genders:    Runner.select(:gender).distinct.map(&:gender)
      }
  end

  def relays
    rows = RelayResult
             .joins(:group)
             .joins("JOIN competitions ON competitions.id = groups.competition_id")
             .joins("LEFT JOIN categories AS relay_cat ON relay_cat.id = relay_results.category_id")
             .joins("JOIN results AS legs ON legs.id = ANY(relay_results.results_id)")
             .joins("JOIN memberships AS m ON m.id = legs.membership_id")
             .where("m.runner_id = ?", @runner.id)
             .select(<<~SQL)
               relay_results.id           AS relay_id,
               relay_results.team         AS team,
               relay_results.place        AS place,
               relay_results.time         AS relay_time,
               legs.id                    AS leg_id,
               legs.time                  AS leg_time,
               array_position(relay_results.results_id, legs.id) AS leg_index,
               COALESCE(array_length(relay_results.results_id, 1), 0) AS leg_count,
               relay_cat.category_name    AS relay_category_name,
               groups.id                  AS group_id,
               groups.group_name          AS group_name,
               competitions.id            AS competition_id,
               competitions.competition_name AS competition_name,
               competitions.date          AS competition_date
             SQL
             .order("competitions.date DESC, groups.group_name ASC, leg_index ASC")

    render json: rows.as_json
  end

  def merge_runners
    merged_runner = Runner.find(params.expect(:merged_runner_id))
    attrs = params[:runner].present? ? runner_params : {}
    @runner.merge_from!(merged_runner, attrs)

    head :ok
  end

  def category_check
    respond_to do |format|
      RunnersCategoryCheck.perform_now

      format.html { redirect_to runners_url, notice: "Runners were successfully updated." }
    end
  end

  def license
    respond_to do |format|
      format.html
      format.json { render json: apply_scopes(index_base_query) }
    end
  end

  def bulk_update_license
    bool = ActiveModel::Type::Boolean.new
    params.require(:runners).each do |row|
      Runner.where(id: row[:id]).update_all(license: bool.cast(row[:license]))
    end
    head :ok
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_runner
    @runner = Runner.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def runner_params
    params.expect(runner: [ :runner_name, :surname, :yob, :gender, :wre_id, :category_valid, :sprint_wre_rang, :forest_wre_rang, :sprint_wre_place, :forest_wre_place, :checksum, :license, :club_id, :category_id, :best_category_id ])
  end

  def index_base_query
    Runner.joins(:category, :best_category, :club).select(
      'runners.*,
      CONCAT(runners.runner_name, \' \', runners.surname) AS full_name,
      clubs.club_name AS club_name,
      categories.category_name AS category_name,
      best_categories_runners.category_name AS best_category_name'
    )
  end
end
