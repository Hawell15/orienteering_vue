class CompetitionsController < ApplicationController
  before_action :set_competition, only: %i[ show edit update destroy group_filters group_ecn_coeficients update_group_clasa new_runners]
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
        format.json { render json: @competition.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /competitions/1 or /competitions/1.json
  def update
    respond_to do |format|
      if @competition.update(competition_params)
        format.json { render json: @competition, status: :ok }
      else
        format.json { render json: @competition.errors, status: :unprocessable_content }
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

  def new_runners
    respond_to do |format|
      format.html
      format.json do
        include_options = {
          club:          { only: [ :id, :club_name ] },
          category:      { only: [ :id, :category_name ] },
          best_category: { only: [ :id, :category_name ] }
        }

        runners = Runner
                    .where(created_at: @competition.created_at..@competition.created_at + 10.minutes)
                    .includes(:club, :category, :best_category)
                    .as_json(include: include_options)

        all_runners = Runner
                        .order(:runner_name, :surname)
                        .includes(:club, :category, :best_category)
                        .as_json(include: include_options)

        render json: { runners: runners, all_runners: all_runners }
      end
    end
  end

  def group_ecn_coeficients
    groups_params = params.require(:groups)

    groups_params.each do |gp|
      group = @competition.groups.find(gp[:id])
      group.update!(ecn_coeficient: gp[:ecn_coeficient])
    end

    EcnProcessor.competition_processor(@competition)

    render json: @competition.groups.order(:group_name).select(:group_name, :ecn_coeficient, :id)
  end

  def update_group_clasa
    results = Result.joins(:group).where("group.competition_id": @competition.id).update_all(category_id: Category::NO_CATEGORY_ID, status: Result::UNCONFIRMED)
    groups_params = params.require(:groups)

    groups_params.each do |gp|
      group = @competition.groups.find(gp[:id])
      group.update!(clasa: gp[:clasa])
      next if group.results.blank?

      GroupCategoriesProcessor.new(group).get_rang_and_categories
    end
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
