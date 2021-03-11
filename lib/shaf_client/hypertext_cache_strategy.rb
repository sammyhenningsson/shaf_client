class ShafClient
  module HypertextCacheStrategy
    AVAILABLE_CACHE_STRATEGIES = [
      CACHE_STRATEGY_NO_CACHE = :no_cache,
      CACHE_STRATEGY_EMBEDDED = :use_embedded,
      CACHE_STRATEGY_FETCH_HEADERS = :fetch_headers
    ]

    class << self
      def cacheable?(strategy)
        [CACHE_STRATEGY_EMBEDDED, CACHE_STRATEGY_FETCH_HEADERS].include? strategy
      end

      def fetch_headers?(strategy)
        CACHE_STRATEGY_FETCH_HEADERS == strategy
      end

      def default_http_status
        203
      end
    end

    def default_hypertext_cache_strategy
      @__default_hypertext_cache_strategy ||= CACHE_STRATEGY_EMBEDDED
    end

    def default_hypertext_cache_strategy=(strategy)
      unless __valid_cache? strategy
        raise Error, <<~ERR
          Unsupported hypertext cache strategy: #{strategy}
          Possible strategies are: #{AVAILABLE_CACHE_STRATEGIES.join(', ')}
        ERR
      end
      @__default_hypertext_cache_strategy = value
    end

    private

    def __valid_cache?(strategy)
      AVAILABLE_CACHE_STRATEGIES.include? strategy
    end
  end
end
