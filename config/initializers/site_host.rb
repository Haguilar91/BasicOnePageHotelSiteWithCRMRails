# The public domain the site is published under.
#
# Every canonical URL, hreflang alternate, Open Graph tag and sitemap entry is
# built from this, so it has to name one host — not whichever Host header
# happens to arrive, which can be an IP, a preview URL, or an attacker-supplied
# value.
#
# Change it by setting the SITE_HOST environment variable (see compose.yaml);
# the default below is what ships, so a normal production deploy needs no
# configuration at all. Write it without a scheme and without a trailing
# slash — "example.com", or "example.com:8443" if a port is genuinely part of
# the public URL. HTTPS is assumed.
Rails.application.configure do
  config.x.site_host = ENV.fetch("SITE_HOST", "hotelmesondelbosque.com.mx")
end
