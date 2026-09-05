class Avo::UsersController < Avo::ResourcesController
  before_action :require_admin!

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to avo.root_path, alert: "No tienes permiso para acceder a esta sección."
    end
  end
end
