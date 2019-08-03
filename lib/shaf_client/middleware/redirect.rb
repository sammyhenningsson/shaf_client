require 'uri'

class ShafClient
  module Middleware
    class Redirect

      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env).on_complete do
          status = env[:status]
          location = env[:response_headers]['Location']
          next unless redirect? status
          next unless location
          update_env(env, status, location)
          @app.call(env)
        end
      end

      def redirect?(status)
        [301, 302, 303, 307, 308].include? status
      end

      def update_env(env, status, location)
        if status == 303
          env[:method] = :get
          env[:body] = nil
        end
        env[:url] = URI(location)
      end
    end
  end
end
