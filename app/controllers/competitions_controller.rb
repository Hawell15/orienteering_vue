class CompetitionsController < ApplicationController
  before_action :set_competition, only: %i[ show edit update destroy ]
  has_scope :search
  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :country
  has_scope :distance_type
  has_scope :wre, type: :boolean
  has_scope :date, using: %i[from to], type: :hash

  # GET /competitions or /competitions.json
  def index
    @competitions = apply_scopes(Competition).all
  end

  # GET /competitions/1 or /competitions/1.json
  def show
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
        format.html { redirect_to @competition, notice: "Competition was successfully created." }
        format.json { render :show, status: :created, location: @competition }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @competition.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /competitions/1 or /competitions/1.json
  def update
    respond_to do |format|
      if @competition.update(competition_params)
        format.html { redirect_to @competition, notice: "Competition was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @competition }
      else
        format.html { render :edit, status: :unprocessable_entity }
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
