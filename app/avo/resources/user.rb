class Avo::Resources::User < Avo::BaseResource
  self.icon = "fas fa-users"

  def self.navigation_label
    "Usuarios"
  end

  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :email, as: :text
    field :avo_preferences, as: :textarea
  end
end
