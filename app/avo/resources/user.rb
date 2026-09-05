class Avo::Resources::User < Avo::BaseResource
  self.icon = "heroicons/outline/users"

  self.visible_on_sidebar = -> { context[:current_user]&.admin? }


  def fields
    field :id, as: :id
    field :email, as: :text
    field :admin, as: :boolean
    field :password, as: :password, required: false
    field :password_confirmation, as: :password, required: false
  end
end
