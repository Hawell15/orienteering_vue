class ClubsController < ApplicationController
  before_action :set_club, only: %i[ show edit update destroy ]

  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :search
  has_scope :runners_count, using: %i[from to], type: :hash

  # GET /clubs or /clubs.json
  def index
    @clubs = apply_scopes(Club)
      .left_joins(:memberships)
      .select("clubs.*, COUNT(memberships.id) AS runners_count")
      .group("clubs.id")
  end

  # GET /clubs/1 or /clubs/1.json
  def show
  end

  # GET /clubs/new
  def new
    @club = Club.new
  end

  # GET /clubs/1/edit
  def edit
  end

  # POST /clubs or /clubs.json
  def create
    @club = Club.new(club_params)

    respond_to do |format|
      if @club.save
        format.html { redirect_to @club, notice: "Club was successfully created." }
        format.json { render :show, status: :created, location: @club }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @club.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clubs/1 or /clubs/1.json
  def update
    respond_to do |format|
      if @club.update(club_params)
        format.html { redirect_to @club, notice: "Club was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @club }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @club.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clubs/1 or /clubs/1.json
  def destroy
    @club.destroy!

    respond_to do |format|
      format.html { redirect_to clubs_path, notice: "Club was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_club
      @club = Club.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def club_params
      params.expect(club: [ :club_name, :territory, :representative, :email, :phone, :alternative_club_name, :formatted_name ])
    end
end
