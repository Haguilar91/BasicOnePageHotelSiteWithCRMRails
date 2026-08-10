class Avo::Resources::User < Avo::BaseResource
  self.icon = "heroicons/outline/users"

  def fields
    field :id, as: :id
    field :email, as: :text
    field :admin, as: :boolean
    field :password, as: :password, required: false
    field :password_confirmation, as: :password, required: false
  end
end