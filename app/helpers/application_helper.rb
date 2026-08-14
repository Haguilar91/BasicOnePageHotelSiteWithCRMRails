module ApplicationHelper
  # Editable copy managed from Avo > Page contents.
  #
  # Loads every key once per request instead of one query per call site, and
  # treats a blank value as "not set" so clearing a field in Avo falls back to
  # the default rather than rendering an empty heading.
  def page_content(key, default = nil)
    @_page_contents ||= PageContent.pluck(:key, :content).to_h
    @_page_contents[key.to_s].presence || default
  end
end
