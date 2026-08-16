# User guide for hotel staff on editing site content through Avo. Open to
# any signed-in account (gated at the route level in config/routes.rb,
# same `authenticate :user do` block as Avo and the Translations panel) —
# unlike TranslationsController, this doesn't require `admin?`, since it's
# read-only reference material, not a content-editing surface.
class DocsController < ApplicationController
  layout "docs"

  def index
    @lang = params[:lang] == "en" ? "en" : "es"
  end
end
