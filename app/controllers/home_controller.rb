class HomeController < ApplicationController
  def index
    respond_to do |format|
      format.html # renders index.html.erb
      format.json { render json:
        {
          runners_count:      Runner.count,
          competitions_count: Competition.count,
          clubs_count:        Club.count,
          results_count:      Result.count
        }
      }
    end
  end
end
