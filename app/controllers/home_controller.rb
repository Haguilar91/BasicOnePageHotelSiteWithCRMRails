class HomeController < ApplicationController
  def index
    # "/", "/es", "/home/index" and "/es/home/index" all land here; the bare
    # root is the one form search engines should keep (see SeoHelper).
    seo_canonical { |options| root_url(**options) }

    @rooms = Room.with_attached_photos.order(:position, :id)
    @experiences = Experience.order(:position, :id)
    @features = Feature.order(:position, :id)
    @local_activities = LocalActivity.order(:category, :position)
    @offers = Offer.visible.ordered.includes(:room)
    # Keyed by room so the room cards can show their discount without a query
    # per room. First match wins when a room has more than one active offer.
    @room_offers = Offer.visible.ordered.room_kind.group_by(&:room_id).transform_values(&:first)
    @hero_image = HeroImage.order(:created_at).first
    # General hotel photos (lobby, terrace, facade...) shown in the "Galería
    # del Hotel" section — distinct from each room's own `photos` gallery.
    @gallery_photos = GalleryPhoto.with_attached_photo.order(:position, :id)
  end
end
