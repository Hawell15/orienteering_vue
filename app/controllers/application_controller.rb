class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user_admin?

  private

  def current_user_admin?
    user_signed_in? && current_user.admin?
  end

  def require_admin!
    return if current_user_admin?

    respond_to do |format|
      format.html { redirect_to root_path, alert: "Acces interzis" }
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
      format.any  { head :forbidden }
    end
  end
end
