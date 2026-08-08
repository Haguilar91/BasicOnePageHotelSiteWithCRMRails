# frozen_string_literal: true

class Pagy
  def urls_hash(**)
    template = compose_page_url(PAGE_TOKEN, **)

    { first:    compose_page_url(nil, **),
      previous: @previous && template.sub(PAGE_TOKEN, @previous.to_s),
      next:     @next     && template.sub(PAGE_TOKEN, @next.to_s),
      last:     @count    && template.sub(PAGE_TOKEN, @last.to_s) }.compact
  end
end
