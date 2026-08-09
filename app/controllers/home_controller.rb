class HomeController < ApplicationController
  def index
    @rooms = Room.order(:position, :id)
    @experiences = Experience.order(:position, :id)
    @features = Feature.order(:position, :id)
    @local_activities = LocalActivity.order(:category, :position)
    @hero_image = HeroImage.order(:created_at).first
  end
  def update_hero_image
    @hero_image = HeroImage.first_or_create
    if params[:hero_image]
      @hero_image.image.attach(params[:hero_image])
      if @hero_image.save
        redirect_to root_path, notice: 'Hero image updated successfully'
      else
        redirect_to root_path, alert: 'Failed to upload image'
      end
    end
  end
end
