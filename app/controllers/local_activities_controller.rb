class LocalActivitiesController < ApplicationController
  def index
    @activities = LocalActivity.order(:category, :position)
  end
end
