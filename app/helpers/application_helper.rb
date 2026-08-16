module ApplicationHelper
  # Editable copy managed from Avo > Page contents.
  #
  # Loads every key once per request instead of one query per call site, and
  # treats a blank value as "not set" so clearing a field in Avo falls back to
  # the default rather than rendering an empty heading.
  def page_content(key, default = nil)
    @_page_contents ||= PageContent.includes(:text_translations).index_by(&:key)
    @_page_contents[key.to_s]&.content.presence || default
  end

  # Rewrites the current path's locale prefix rather than going through
  # `url_for` — "root" and "home/index" both map to home#index, so
  # `url_for(locale: ...)` can't reliably tell which named route to rebuild
  # from and sometimes produces the uglier "/en/home/index" instead of "/en".
  def switch_locale_path(new_locale)
    path = request.path.sub(%r{\A/(en|es)(?=/|\z)}, "")
    path = "" if path == "/"
    path = "/#{new_locale}#{path}" unless new_locale.to_s == I18n.default_locale.to_s
    path = "/" if path.blank?
    request.query_string.presence ? "#{path}?#{request.query_string}" : path
  end
end
