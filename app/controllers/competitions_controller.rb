class CompetitionsController < ApplicationController
  before_action :set_competition, only: %i[ show edit update destroy group_filters group_ecn_coeficients update_group_clasa new_runners reimport_wre_points telegram_results]
  before_action :require_admin!, only: %i[new create edit update destroy group_ecn_coeficients update_group_clasa new_runners reimport_wre_points telegram_results]
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
      format.json { render json: @competition.as_json.merge(relay: @competition.relay?) }
      format.pdf do
        load_pdf_data

        style    = %w[default modern minimal].include?(params[:style]) ? params[:style] : "default"
        suffix   = style == "default" ? "" : "_#{style}"
        template = "competitions/pdf#{suffix}"
        layout   = "pdf#{suffix}"

        html = render_to_string(template: template, layout: layout, formats: [ :html ])
        pdf  = Grover.new(html, display_url: request.base_url).to_pdf

        send_data pdf,
                  filename:    "#{@competition.competition_name.to_s.parameterize}-#{@competition.id}#{suffix}.pdf",
                  type:        "application/pdf",
                  disposition: "inline"
      end
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

  def ecn_ranking
    respond_to do |format|
      format.html
      format.json do
        gender = params[:gender].presence || "M"
        date   = params[:date].presence  || Date.current
        ranking = EcnProcessor.ranking(gender, date).includes(:club)
        render json: ranking.as_json(
          methods: [ :total_points, :ecn_results_count, :place ],
          only:    [ :id, :runner_name, :surname, :yob, :club_id, :gender ],
          include: { club: { only: [ :id, :club_name ] } }
        )
      end
    end
  end

  def ecn_runner_results
    runner = Runner.find(params[:runner_id])
    date   = params[:date].presence || Date.current
    data   = EcnProcessor.runner_results(runner, date)

    render json: {
      min_limit_points: data[:min_limit_points],
      limit_number:     data[:limit_number],
      results: data[:results].as_json(
        only:    [ :id, :date, :place, :ecn_points ],
        include: {
          group: {
            only:    [ :id, :group_name ],
            include: { competition: { only: [ :id, :competition_name ] } }
          }
        }
      )
    }
  end

  def group_filters
    render json:
    {
      groups: @competition.groups.select(:id, :group_name).order(:group_name).as_json,
      ecn: @competition.ecn.present?,
      wre: @competition.wre_id.present?,
      relay: @competition.relay?
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
    Result.joins(:group).where("group.competition_id": @competition.id).update_all(category_id: Category::NO_CATEGORY_ID, status: Result::UNCONFIRMED)
    RelayResult.where(group_id: @competition.groups).update_all(category_id: Category::NO_CATEGORY_ID) if @competition.relay?

    params.require(:groups).each do |gp|
      group = @competition.groups.find(gp[:id])
      group.update!(clasa: gp[:clasa])

      processor, scope = group.competition.relay? ?
                          [ RelayGroupCategoriesProcessor, group.relay_results ] :
                          [ GroupCategoriesProcessor,      group.results ]
      next if scope.blank?

      processor.new(group).get_rang_and_categories
    end
  end

  def reimport_wre_points
    return render json: { error: "Competition has no wre_id" }, status: :unprocessable_content unless @competition.wre_id

    updated = WreRaceReimporter.new(@competition).call

    render json: { updated: updated }
  end

  def telegram_results
    sent = TelegramCompetitionNotifier.notify(@competition, host: request.base_url)
    render json: { sent: sent }
  rescue TelegramNotifier::TokenMissingError => e
    render json: { sent: 0, error: e.message }, status: :service_unavailable
  end

  private
    # Use callbacks to share compmon setup or constraints between actions.
    def set_competition
      @competition = Competition.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def competition_params
      params.expect(competition: [ :competition_name, :date, :location, :country, :distance_type, :wre_id, :checksum, :ecn ])
    end

    def load_pdf_data
      @pdf_groups = @competition.groups
                                .includes(results: [
                                  :category,
                                  { child_results: :category },
                                  { membership: [ :club, :runner ] }
                                ])
                                .order(:group_name)
                                .to_a

      result_ids = @pdf_groups.flat_map { |g| g.results.map(&:id) }

      @runner_actual_category_name_by_result_id =
        if result_ids.any?
          Result.where(id: result_ids)
                .joins(membership: :runner)
                .with_runner_category_on_date
                .pluck(:id, "runner_actual_category.category_name")
                .to_h
        else
          {}
        end

      if @competition.relay?
        relay_results = RelayResult
                          .where(group_id: @pdf_groups.map(&:id))
                          .order(:place)
                          .to_a
        @pdf_relay_results_by_group_id = relay_results.group_by(&:group_id)

        leg_ids = relay_results.flat_map { |r| r.results_id || [] }.compact.uniq
        @pdf_legs_by_id = if leg_ids.any?
          Result.where(id: leg_ids)
                .includes(:category, membership: [ :club, :runner ])
                .index_by(&:id)
        else
          {}
        end
      else
        @pdf_relay_results_by_group_id = {}
        @pdf_legs_by_id                = {}
      end
    end
end
