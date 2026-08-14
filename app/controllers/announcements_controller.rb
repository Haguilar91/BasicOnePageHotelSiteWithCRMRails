class AnnouncementsController < ApplicationController
  before_action :set_announcement, only: %i[ show ]

  # GET /announcements
  def index
    @announcements = Announcement.all
    # The ticker links here and can carry offers, so this page lists them too.
    @offers = Offer.visible.ordered.includes(:room)
  end

  # GET /announcements/1
  def show
  end

  private
    def set_announcement
      @announcement = Announcement.find(params.expect(:id))
    end
end
