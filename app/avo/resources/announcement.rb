# app/avo/resources/announcement.rb
class Avo::Resources::Announcement < Avo::BaseResource
  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :start_date, as: :date
    field :end_date, as: :date_time
    field :active, as: :boolean
  end
end