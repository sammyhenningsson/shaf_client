require 'uri'

class ShafClient
  module Middleware
    class Redirect

      def initialize(app)
        @app = app
      end

      def call(request_env)
        @app.call(request_env).on_complete do |response_env|
          status = response_env[:status]
          location = response_env[:response_headers]['Location']
          next unless redirect? status
          next unless location
          update_env(request_env, status, location)
          @app.call(request_env)
        end
      end

      def redirect?(status)
        [301, 302, 303, 307, 308].include? status
      end

      def update_env(request_env, status, location)
        if status == 303
          request_env[:method] = :get
          request_env[:body] = nil
        end
        request_env[:url] = URI(location)
      end
    end
  end
end
