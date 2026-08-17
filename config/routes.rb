Rails.application.routes.draw do
  devise_for :users, skip: [:registration]

  # Everything that can change site content lives behind login. Not
  # locale-scoped — internal tools, no public/SEO surface, and Avo's own UI
  # is already Spanish-only (config.locale = :es).
  authenticate :user do
    mount Avo::Engine => '/avo'

    # Not a standard `resources :translations` — #update saves a whole batch
    # of records across multiple models in one submit (see
    # TranslationsController), not a single record by :id, so it's a plain
    # collection-level route rather than a RESTful member route.
    get "translations", to: "translations#index", as: :translations
    patch "translations", to: "translations#update"
    post "translations/translate", to: "translations#translate", as: :translate_translations

    get "docs", to: "docs#index", as: :docs

    # Easy Edit: a WYSIWYG-ish overlay on the live public site (enabled via a
    # session flag) that lets an admin click a pencil icon on a room/offer/
    # etc. card and edit its text/photo fields in a modal, without leaving
    # the page. #enable and #disable just flip the session flag and bounce
    # back to wherever the admin was; #edit/#update aren't RESTful member
    # routes on a single resource type — they're dispatched by a
    # `:resource` param (see EasyEditController::MODELS).
    get "easy_edit/enable", to: "easy_edit#enable", as: :enable_easy_edit
    get "easy_edit/disable", to: "easy_edit#disable", as: :disable_easy_edit
    get "easy_edit/:resource/:id/edit", to: "easy_edit#edit", as: :edit_easy_edit
    patch "easy_edit/:resource/:id", to: "easy_edit#update", as: :easy_edit
  end

  # Path-based locale for the public site (/es, /en) for SEO-visible,
  # crawlable URLs per language. The locale segment is optional, so "/",
  # "/es", and "/en" all resolve here — see ApplicationController#switch_locale
  # for how the locale actually gets applied.
  scope "(:locale)", locale: /en|es/ do
    # Public read-only pages (promos visitors can browse). All writes for
    # these records happen through Avo, which is why only index/show are
    # exposed here.
    resources :announcements, only: [:index, :show]

    get "home/index"
    # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
    # Can be used by load balancers and uptime monitors to verify that the app is live.
    # get "up" => "rails/health#show", as: :rails_health_check
    # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
    # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
    # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
    # Defines the root path route ("/")
    root "home#index"
  end
end
