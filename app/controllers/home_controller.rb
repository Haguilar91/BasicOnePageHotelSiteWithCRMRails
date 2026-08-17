class HomeController < ApplicationController
  def index
    @rooms = Room.with_attached_photos.order(:position, :id)
    @experiences = Experience.order(:position, :id)
    @features = Feature.order(:position, :id)
    @local_activities = LocalActivity.order(:category, :position)
    @offers = Offer.visible.ordered.includes(:room)
    # Keyed by room so the room cards can show their discount without a query
    # per room. First match wins when a room has more than one active offer.
    @room_offers = Offer.visible.ordered.room_kind.group_by(&:room_id).transform_values(&:first)
    @hero_image = HeroImage.order(:created_at).first
  end
end
