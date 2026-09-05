class AnnouncementsController < ApplicationController
  before_action :set_announcement, only: %i[ show ]

  # GET /announcements
  def index
    seo_canonical { |options| announcements_url(**options) }
    @seo_description = t("seo.announcements_description")
    @announcements = Announcement.all
    # The ticker links here and can carry offers, so this page lists them too.
    @offers = Offer.visible.ordered.includes(:room)
  end

  # GET /announcements/1
  def show
    seo_canonical { |options| announcement_url(@announcement, **options) }
    # The announcement's own text is a far better search snippet and link
    # preview than the site-wide default.
    @seo_description = @announcement.description
  end

  private
    def set_announcement
      @announcement = Announcement.find(params.expect(:id))
    end
end
