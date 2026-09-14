require "net/http"
require "uri"

# Fetches the currently-playing track title from a Shoutcast/Icecast stream's
# own inline ICY metadata (see http://www.smackfu.com/stuff/programming/shoutcast.html).
#
# This has to happen server-side rather than in the browser: even when a
# stream server allows cross-origin reads of the audio bytes themselves,
# browsers still hide non-standard response headers like `icy-metaint` from
# JavaScript unless the server also sends Access-Control-Expose-Headers,
# which in practice almost none of them do.
class IcyNowPlaying
  MAX_REDIRECTS = 5
  MAX_METADATA_BLOCK_BYTES = 255 * 16 # ICY spec: length byte * 16, so up to 4080 bytes
  TIMEOUT = 6 # seconds, each of open/read

  # Returns the track title (String) or nil if it can't be determined for
  # any reason (no icy-metaint, connection failure, timeout, unparseable...).
  def self.fetch_title(url)
    new(url).fetch_title
  end

  def initialize(url)
    @url = url
  end

  def fetch_title
    fetch(@url, MAX_REDIRECTS)
  rescue StandardError
    nil
  end

  private

  def fetch(url, redirects_left)
    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Icy-MetaData"] = "1"
      request["User-Agent"] = "radiogugu-now-playing/1.0"

      http.request(request) do |response|
        case response
        when Net::HTTPRedirection
          return nil if redirects_left <= 0
          return fetch(response["location"], redirects_left - 1)
        when Net::HTTPSuccess
          return parse_title(response)
        else
          return nil
        end
      end
    end
  end

  def parse_title(response)
    meta_int = response["icy-metaint"].to_i
    return nil if meta_int <= 0

    buffer = +""
    buffer.force_encoding(Encoding::ASCII_8BIT)

    title = nil
    response.read_body do |chunk|
      buffer << chunk

      if buffer.bytesize > meta_int
        meta_len = buffer.getbyte(meta_int) * 16
        if meta_len > MAX_METADATA_BLOCK_BYTES
          break
        elsif buffer.bytesize >= meta_int + 1 + meta_len
          meta = buffer.byteslice(meta_int + 1, meta_len).dup.force_encoding(Encoding::UTF_8).scrub
          title = meta[/StreamTitle='([^']*)'/, 1]
          break
        end
      end

      # Safety valve: bail out if we've read way more than expected without
      # finding a complete metadata block (malformed/unexpected stream).
      break if buffer.bytesize > meta_int + 1 + MAX_METADATA_BLOCK_BYTES
    end

    title&.strip.presence
  end
end
