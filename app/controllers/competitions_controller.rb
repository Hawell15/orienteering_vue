class CompetitionsController < ApplicationController
  before_action :set_competition, only: %i[ show edit update destroy group_filters]
  has_scope :search
  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :country
  has_scope :distance_type
  has_scope :wre, type: :boolean
  has_scope :ecn, type: :boolean
  has_scope :date, using: %i[from to], type: :hash

  # GET /competitions or /competitions.json
  def index
    respond_to do |format|
      format.html # renders index.html.erb
      format.json { render json: apply_scopes(Competition).limit(params[:limit]) }
    end
  end

  # GET /competitions/1 or /competitions/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render json: @competition }
    end
  end

  # GET /competitions/new
  def new
    @competition = Competition.new
  end

  # GET /competitions/1/edit
  def edit
  end

  # POST /competitions or /competitions.json
  def create
    @competition = Competition.new(competition_params)

    respond_to do |format|
      if @competition.save
        format.json { render json: @competition, status: :ok }
      else
        format.json { render json: @competition.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /competitions/1 or /competitions/1.json
  def update
    respond_to do |format|
      if @competition.update(competition_params)
        format.json { render json: @competition, status: :ok }
      else
        format.json { render json: @competition.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /competitions/1 or /competitions/1.json
  def destroy
    @competition.destroy!

    respond_to do |format|
      format.html { redirect_to competitions_path, notice: "Competition was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def filters
    unique_values = Competition.select(:country, :distance_type).distinct

    render json:
      {
        countries:      unique_values.map(&:country).compact.sort.uniq,
        distance_types: unique_values.map(&:distance_type).compact.sort.uniq
      }
  end

  def distance_types
   render json:  Competition::DISTANCE_TYPES
  end

  def group_filters
    render json:
    {
      groups: @competition.groups.select(:id, :group_name).order(:group_name).as_json,
      ecn: @competition.ecn.present?,
      wre: @competition.wre_id.present?
    }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_competition
      @competition = Competition.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def competition_params
      params.expect(competition: [ :competition_name, :date, :location, :country, :distance_type, :wre_id, :checksum, :ecn ])
    end
end
