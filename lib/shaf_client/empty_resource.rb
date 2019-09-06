require 'shaf_client/resource'

class ShafClient
  class EmptyResource < Resource
    attr_reader :http_status, :headers

    profile '__shaf_client_emtpy__'

    def initialize(_client, _payload, status = nil, headers = {})
      @http_status = status
      @headers = headers
      @attributes = {}.freeze
      @links = {}.freeze
      @curies = {}.freeze
      @embedded_resources = {}.freeze
    end

    %i[get put post delete patch, get_doc, reload!].each do |method|
      define_method(method) do |*_args|
        raise "EmptyResource: #{method} not available"
      end
    end
  end
end
