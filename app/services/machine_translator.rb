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
  WARNING_MARKERS = [ "MYMEMORY WARNING", "QUERY LENGTH LIMIT", "INVALID" ].freeze

  # Matches a run of decorative emoji (plus the whitespace around them) at
  # the start/end of a string — used to shield emoji from MyMemory before
  # translating. See #fetch_translation for why.
  DECORATIVE_EMOJI_RUN = /[\p{Extended_Pictographic}\u{FE0F}\u{200D}\s]/

  Result = Struct.new(:text, :ok, :error, keyword_init: true) do
    alias_method :ok?, :ok
  end

  def self.translate(text, from:, to:)
    new.translate(text, from: from, to: to)
  end

  def translate(text, from:, to:)
    return Result.new(text: "", ok: true, error: nil) if text.blank?

    cache_key = [ "machine_translator", from, to, text ]
    cached = Rails.cache.read(cache_key)
    return Result.new(text: cached, ok: true, error: nil) if cached

    result = fetch_translation(text, from, to)
    Rails.cache.write(cache_key, result.text, expires_in: CACHE_TTL) if result.ok?
    result
  end

  private

  # MyMemory's top-level `translatedText` is whichever entry in its
  # translation-memory corpus scored highest overall, not necessarily a
  # faithful translation of *our* exact string — for short marketing copy
  # wrapped in decorative emoji (e.g. "🎉 ¡Temporada de Verano!"), a fuzzy
  # match from someone else's plain-text memory entry routinely outscores
  # the live translation of our literal query, silently dropping the emoji.
  # Rather than fight that scoring, leading/trailing emoji are stripped
  # before the request and stitched back on after — MyMemory only ever
  # sees (and can only ever mangle) the plain-text core.
  def fetch_translation(text, from, to)
    leading, core, trailing = split_decorative_emoji(text)
    return Result.new(text: text, ok: true, error: nil) if core.blank?

    result = fetch_core_translation(core, from, to)
    return result unless result.ok?

    Result.new(text: [ leading, result.text, trailing ].compact_blank.join(" "), ok: true, error: nil)
  end

  def split_decorative_emoji(text)
    match = text.match(/\A(#{DECORATIVE_EMOJI_RUN}*)(.*?)(#{DECORATIVE_EMOJI_RUN}*)\z/m)
    return [ nil, text, nil ] unless match

    [ match[1].strip.presence, match[2].strip, match[3].strip.presence ]
  end

  def fetch_core_translation(text, from, to)
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
