class ResultsController < ApplicationController
  before_action :set_result, only: %i[ show edit update destroy ]

  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :search
  has_scope :runner
  has_scope :club
  has_scope :competition
  has_scope :group_data
  has_scope :category
  has_scope :wre, type: :boolean
  has_scope :ecn, type: :boolean
  has_scope :date, using: %i[from to], type: :hash
  has_scope :status, type: :array

  # GET /results or /results.json
  def index
    respond_to do |format|
      format.html # renders index.html.erb
      format.json { render json: apply_scopes(index_base_query).limit(1000) }
    end
  end

  # GET /results/1 or /results/1.json
  def show
  end

  # GET /results/new
  def new
    @result = Result.new
  end

  # GET /results/1/edit
  def edit
  end

  # POST /results or /results.json
  def create
    @result = Result.new(result_params)

    respond_to do |format|
      if @result.save
        format.html { redirect_to @result, notice: "Result was successfully created." }
        format.json { render :show, status: :created, location: @result }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @result.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /results/1 or /results/1.json
  def update
    respond_to do |format|
      if @result.update(result_params)
        format.html { redirect_to @result, notice: "Result was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @result }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @result.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /results/1 or /results/1.json
  def destroy
    @result.destroy!

    respond_to do |format|
      format.html { redirect_to results_path, notice: "Result was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

   def filters
    render json:  {
        clubs:   Club.select(:id, :club_name).order(:club_name).as_json,
        runners: Runner.select(:id, "CONCAT(runner_name, \' \', surname) AS full_name").order(:runner_name, :surname).as_json,
        competitions: Competition.select(:id, :competition_name).order(date: :desc).as_json,
        categories: Category.select(:id, :category_name).order(:id).as_json
      }
  end

  def group_filters
    render json: Group.competition(params[:competition]).select(:id, :group_name).order(:group_name).as_json
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_result
      @result = Result.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def result_params
      params.expect(result: [ :place, :time, :wre_points, :date, :ecn_points, :status, :runner_id, :category_id, :group_id ])
    end

    def index_base_query
      Result
        .left_joins(:category, membership: [ :runner, :club ], group: :competition)
        .with_runner_category_on_date
        .select(<<~SQL)
          results.*,
          CONCAT(runners.runner_name, ' ', runners.surname) AS full_name,
          runners.id AS runner_id,
          clubs.club_name AS club_name,
          clubs.id AS club_id,
          categories.category_name AS result_category_name,
          categories.id AS result_category_id,
          runner_actual_category.category_name AS runner_category_name,
          runner_actual_category.id AS runner_category_id,
          competitions.competition_name AS competition_name,
          competitions.id AS competition_id,
          groups.group_name AS group_name,
          groups.id AS group_id
        SQL
    end
end
