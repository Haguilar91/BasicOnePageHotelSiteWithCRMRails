# frozen_string_literal: true

require_relative 'support/data_pagy_attribute'

class Pagy
  module NumericHelpers
    def limit_tag_js(id: nil, item_name: nil, max_limit: @options[:max_limit], **)
      raise OptionError.new(self, :max_limit, 'to be truthy', max_limit) unless max_limit

      limit_input = %(<input name="limit" type="number" min="1" max="#{max_limit}" value="#{
                      @limit}" style="padding: 0; text-align: center; width: #{@limit.to_s.length + 1}rem;">#{A_TAG})

      url_token = compose_page_url(PAGE_TOKEN, limit: LIMIT_TOKEN)

      %(<span#{%( id="#{id}") if id} class="pagy limit-tag-js" #{
        data_pagy_attribute(:ltj, @from, url_token, PAGE_TOKEN, LIMIT_TOKEN)
        }><label>#{
        I18n.translate('pagy.limit_tag_js',
                       item_name: item_name || I18n.translate('pagy.item_name', count: @limit),
                       limit_input:,
                       count: @limit)
        }</label></span>)
    end
  end
end
