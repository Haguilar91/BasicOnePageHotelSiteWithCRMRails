# Thin wrapper around the free MyMemory translation API
# (https://mymemory.translated.net/doc/spec.php) — no signup/API key
# required. Used only from the admin Translations panel (TranslationsController),
# triggered by an explicit "Translate" click; never on a public request path.
class MachineTranslator
  ENDPOINT = URI("https://api.mymemory.translated.net/get")
  CACHE_TTL = 30.days

  # MyMemory returns HTTP 200 even when it can't translate (quota exceeded,
  # invalid request), embedding a warning string inside translatedText
  # instead of a clean error status — these markers catch that so the panel
  # shows a real error rather than saving the warning text as a "translation".
  WARNING_MARKERS = ["MYMEMORY WARNING", "QUERY LENGTH LIMIT", "INVALID"].freeze

  Result = Struct.new(:text, :ok, :error, keyword_init: true) do
    alias_method :ok?, :ok
  end

  def self.translate(text, from:, to:)
    new.translate(text, from: from, to: to)
  end

  def translate(text, from:, to:)
    return Result.new(text: "", ok: true, error: nil) if text.blank?

    cache_key = ["machine_translator", from, to, text]
    cached = Rails.cache.read(cache_key)
    return Result.new(text: cached, ok: true, error: nil) if cached

    result = fetch_translation(text, from, to)
    Rails.cache.write(cache_key, result.text, expires_in: CACHE_TTL) if result.ok?
    result
  end

  private

  def fetch_translation(text, from, to)
    uri = ENDPOINT.dup
    query = { q: text, langpair: "#{from}|#{to}" }
    contact_email = Rails.application.credentials.dig(:mymemory, :contact_email)
    query[:de] = contact_email if contact_email.present?
    uri.query = URI.encode_www_form(query)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.get(uri)
    end

    unless response.is_a?(Net::HTTPSuccess)
      return Result.new(text: nil, ok: false, error: "HTTP #{response.code}")
    end

    payload = JSON.parse(response.body)
    translated = payload.dig("responseData", "translatedText").to_s

    if payload["responseStatus"].to_i >= 400 || WARNING_MARKERS.any? { |marker| translated.include?(marker) }
      return Result.new(text: nil, ok: false, error: translated.presence || "MyMemory error (status #{payload["responseStatus"]})")
    end

    Result.new(text: strip_segment_markup(translated), ok: true, error: nil)
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
    Result.new(text: nil, ok: false, error: e.message)
  end

  # Some translation-memory matches come back wrapped in CAT-tool style
  # segment tags (e.g. `<g id="1">...</g>`) instead of plain text — strip any
  # tag-like markup and collapse the whitespace it leaves behind, since
  # translated copy should never legitimately contain markup.
  def strip_segment_markup(text)
    text.gsub(/<\/?[a-z][^>]*>/i, " ").squeeze(" ").strip
  end
end
