faraday_version = Gem.loaded_specs['faraday']&.version.to_s
faraday_http_cache_version = Gem.loaded_specs['faraday-http-cache']&.version.to_s

if faraday_version.start_with?("0.16") && faraday_http_cache_version <= '2.0.0'
  module Faraday
    class HttpCache < Faraday::Middleware
      def create_response(env)
        hash = env.to_hash
        {
          status: hash[:status],
          body: hash[:response_body] || hash[:body],
          response_headers: hash[:response_headers]
        }
      end
    end
  end
end
