module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
  end

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Not authorized."
    end
  end
end
