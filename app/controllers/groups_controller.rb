class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]
  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :search
  has_scope :competition
  has_scope :results_count, using: %i[from to], type: :hash
  has_scope :date, using: %i[from to], type: :hash

  # GET /groups or /groups.json
  def index
    base_query = Group.left_joins(:competition, :results)
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
    @groups = apply_scopes(base_query)
  end

  # GET /groups/1 or /groups/1.json
  def show
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
        format.html { redirect_to @group, notice: "Group was successfully created." }
        format.json { render :show, status: :created, location: @group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1 or /groups/1.json
  def update
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to @group, notice: "Group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @group.errors, status: :unprocessable_entity }
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
        competitions: Competition.select(:id, "CONCAT(competition_name, \'(\', TO_CHAR(date, 'DD-MM-YYYY'), \')\') AS competition_display").order(date: :desc, competition_name: :asc).as_json
      }
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
end
