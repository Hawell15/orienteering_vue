class MembershipsController < ApplicationController
  before_action :set_membership, only: %i[ show edit update destroy ]
  has_scope :search
  has_scope :sorting, using: %i[sort_by direction], type: :hash
  has_scope :club_id
  has_scope :runner_id
  has_scope :results_count, using: %i[from to], type: :hash

  # GET /memberships or /memberships.json
  def index
    @memberships = apply_scopes(Membership)
      .left_joins(:club, :runner, :results)
      .select(
        'memberships.*,
         clubs.id AS club_id,
         runners.id AS runners_id,
         clubs.club_name AS club_name,
         CONCAT(runners.runner_name, \' \', runners.surname) AS full_name,
         COUNT(results.id) AS results_count'
      )
      .group(
        'memberships.id,
         clubs.id,
         runners.id,
         clubs.club_name,
         runners.runner_name,
         runners.surname'
      )
  end

  # GET /memberships/1 or /memberships/1.json
  def show
  end

  # GET /memberships/new
  def new
    @membership = Membership.new
  end

  # GET /memberships/1/edit
  def edit
  end

  # POST /memberships or /memberships.json
  def create
    @membership = Membership.new(membership_params)

    respond_to do |format|
      if @membership.save
        format.html { redirect_to @membership, notice: "Membership was successfully created." }
        format.json { render :show, status: :created, location: @membership }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /memberships/1 or /memberships/1.json
  def update
    respond_to do |format|
      if @membership.update(membership_params)
        format.html { redirect_to @membership, notice: "Membership was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @membership }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /memberships/1 or /memberships/1.json
  def destroy
    @membership.destroy!

    respond_to do |format|
      format.html { redirect_to memberships_path, notice: "Membership was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def filters
    render json:
      {
        clubs:   Club.select(:id, :club_name).as_json,
        runners: Runner.select(:id, "CONCAT(runner_name, \' \', surname) AS full_name").as_json
      }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_membership
      @membership = Membership.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def membership_params
      params.expect(membership: [ :runner_id, :club_id, :main ])
    end
end
