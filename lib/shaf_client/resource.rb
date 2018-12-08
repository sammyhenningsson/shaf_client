require 'json'
require 'shaf_client/base_resource'

class ShafClient
  class Resource < BaseResource

    def initialize(client, payload)
      @client = client
      super(payload)
    end

    %i[get put post delete patch get_form].each do |method|
      define_method(method) do |rel, payload = nil|
        href = link(rel).href
        args = [method, href]
        args << payload unless method.to_s.start_with? 'get'
        client.send(*args)
      end
    end

    private

    attr_reader :client
  end
end
