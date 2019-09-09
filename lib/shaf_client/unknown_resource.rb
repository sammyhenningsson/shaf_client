require 'shaf_client/resource'

class ShafClient
  class UnknownResource < Resource
    attr_reader :http_status, :headers, :body

    ResourceMapper.default = self

    def initialize(_client, payload, status = nil, headers = {})
      @body = payload.freeze
      @http_status = status
      @headers = headers
      @attributes = {}.freeze
      @links = {}.freeze
      @curies = {}.freeze
      @embedded_resources = {}.freeze
    end

    def to_h
      {}
    end

    %i[get put post delete patch, get_doc, reload!].each do |method|
      define_method(method) do |*_args|
        raise "UnknownResource: #{method} not available"
      end
    end
  end
end
