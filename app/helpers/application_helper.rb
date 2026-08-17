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

  # Whether the "Easy Edit" WYSIWYG overlay should render on this page.
  # Double-checks admin? on every render (not just at toggle time) so the
  # overlay disappears immediately if the account is ever demoted mid-session.
  def easy_edit_mode?
    session[:easy_edit].present? && current_user&.admin?
  end

  # Whether a CTA contact button (:call, :whatsapp, :email) should render.
  # Controlled from the "global" PageContent record in Avo, so an admin can
  # hide a channel they don't want to offer (e.g. phone calls) without losing
  # its configuration — the button markup and its data stay intact either way.
  def cta_button_enabled?(button)
    @_page_contents ||= PageContent.includes(:text_translations).index_by(&:key)
    global = @_page_contents["global"]
    global.nil? || global.public_send("show_cta_#{button}")
  end

  # Wraps a page_content value with an Easy Edit pencil trigger when edit
  # mode is on; otherwise renders identically to a plain page_content call,
  # so this is safe to use everywhere page_content already is.
  def editable_content(key, default = nil, tag: :span, raw_html: false, css_class: nil)
    text = page_content(key, default)
    rendered = raw_html ? raw(text) : text
    return rendered unless easy_edit_mode?

    content_tag(tag, rendered, class: class_names("easy-edit-editable", css_class), data: {
      easy_edit_trigger: true,
      easy_edit_resource: "page_content",
      easy_edit_id: key
    })
  end
end
