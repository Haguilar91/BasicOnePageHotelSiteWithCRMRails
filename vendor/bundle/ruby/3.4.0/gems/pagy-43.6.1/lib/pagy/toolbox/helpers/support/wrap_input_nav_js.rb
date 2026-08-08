# frozen_string_literal: true

require_relative 'nav_aria_label_attribute'
require_relative 'data_pagy_attribute'

class Pagy
  private

  # Common input_nav_js logic
  def wrap_input_nav_js(html, nav_classes, id: nil, aria_label: nil, **)
    %(<nav#{%( id="#{id}") if id} class="#{nav_classes}" #{
      nav_aria_label_attribute(aria_label:)} #{
      data = [:inj, compose_page_url(PAGE_TOKEN, **), PAGE_TOKEN]
      data.push(@update) if keynav?
      data_pagy_attribute(*data)
      }>#{html}</nav>)
  end
end
