class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy count_rang]
  before_action :require_admin!, only: %i[new create edit update destroy count_rang]
  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :search
  has_scope :competition
  has_scope :clasa
  has_scope :results_count, using: %i[from to], type: :hash
  has_scope :date, using: %i[from to], type: :hash

  # GET /groups or /groups.json
  def index
    respond_to do |format|
      format.html # renders index.html.erb
      format.json { render json: apply_scopes(index_base_query) }
    end
  end

  # GET /groups/1 or /groups/1.json
  def show
    category_name = Category.find_by(id: @group.clasa)&.category_name
    category_percentages = GroupCategoriesProcessor.new(@group).get_percent_and_times

    respond_to do |format|
      format.html # renders index.html.erb
      format.json do
        render json: @group.as_json(include: :competition).merge(
          "category_name" => category_name,
          "category_percentages" => category_percentages,
          "relay" => @group.competition.relay?
        )
      end
    end
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups or /groups.json
  def create
    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        format.json { render json: index_base_query.find(@group.id), status: :ok }
      else
        format.json { render json: @group.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    respond_to do |format|
      if @group.update(group_params)
        format.json { render json: index_base_query.find(@group.id), status: :ok }
      else
        format.json { render json: @group.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /groups/1 or /groups/1.json
  def destroy
    @group.destroy!

    respond_to do |format|
      format.html { redirect_to groups_path, notice: "Group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

   def filters
    render json:
      {
        competitions: Competition.select(:id, :ecn, "CONCAT(competition_name, \'(\', TO_CHAR(date, 'DD-MM-YYYY'), \')\') AS competition_display").order(date: :desc, competition_name: :asc).as_json,
        clase: Category.where(id: [ 2, 3, 4, 5, 7, 10 ]).select(:id, :category_name).as_json
      }
  end

  def count_rang
    GroupCategoriesProcessor.new(@group).get_rang_and_categories
    head :ok
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def group_params
    params.expect(group: [ :group_name, :rang, :clasa, :ecn_coeficient, :competition_id ])
  end

  def index_base_query
    Group.left_joins(:competition, :results)
    .joins("LEFT JOIN categories ON categories.id = CAST(groups.clasa AS integer)")
    .select(
      'groups.*,
      competitions.competition_name AS competition_name,
      competitions.id AS competition_id,
      categories.category_name AS clasa_name,
      competitions.date AS date,
      COUNT(results.id) AS results_count'
    )
    .group(
      'groups.id,
      categories.id,
      competitions.id'
    )
  end
end
