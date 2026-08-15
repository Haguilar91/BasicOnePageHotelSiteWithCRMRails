class ApplicationController < ActionController::Base
  # `allow_browser versions: :modern` used to guard every page here, but it
  # answers 406 to anything older than Safari 17.2 / Chrome 120 — including
  # phones guests actually book from, and with an unstyled error page. This is
  # a public hotel site that uses no import maps, web push or badges, so the
  # guard costs real bookings and buys nothing.
end
