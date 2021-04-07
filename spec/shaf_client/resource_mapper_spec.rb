require 'spec_helper'

class ShafClient
  describe ResourceMapper do
    let(:clazz) { Class.new(Resource) }
    let(:content_type) { 'application/vnd.foobar' }
    let(:profile_url) { 'https://foo.bar/profile' }
    let(:profile_urn) { 'urn:foo:bar' }
    let(:class_with_profile) { Class.new(clazz) }
    let(:other_content_type) { 'application/other' }
    let(:client) { ShafClient.new('https://api.root.com', faraday_adapter: :test) }
    let(:stubs) { client.stubs }
    let(:alps_profile) do
      <<~ALPS
        {
          "alps": {
            "version": "1.0",
            "descriptor": [
              {
                "id": "publish",
                "type": "idempotent",
                "doc": {
                  "value": "Some foo"
                },
                "name": "publish",
                "ext": [
                  {
                    "id": "http_method",
                    "href": "https://gist.github.com/sammyhenningsson/2103d839eb79a7baf8854bfb96bda7ae",
                    "value": [
                      "PUT"
                    ]
                  }
                ]
              }
            ]
          }
        }
      ALPS
    end
    let(:payload) do
      <<~HAL
        {
          "message": "hello",
          "_links": {
            "profile": {
              "href": "#{profile_url}"
            },
            "self": {
              "href": "http://localhost:3000/posts/1"
            },
            "doc:publish": {
              "href": "the/publishing/url"
            },
            "curies": [
              {
                "name": "doc",
                "href": "http://localhost:3000/doc/profiles/post{#rel}",
                "templated": true
              }
            ]
          }
        }
      HAL
    end

    before do
      ResourceMapper.register(content_type, clazz)
      ResourceMapper.register(content_type, profile_url, class_with_profile)
      ResourceMapper.register(content_type, profile_urn, class_with_profile)
      ResourceMapper.register(other_content_type, Float)
    end

    describe 'content type without profile' do
      it 'returns registered class for content type' do
        result, extensions = ResourceMapper.for(content_type: content_type)

        _(result).must_equal clazz
        _(extensions).must_equal []
      end
    end

    describe 'registered content type with profile' do
      it 'looks up profile from url in content type' do
        content_type_with_profile = "#{content_type}; profile=#{profile_url}"

        result, extensions = ResourceMapper.for(
          content_type: content_type_with_profile
        )

        _(result).must_equal class_with_profile
        _(extensions).must_equal []
      end

      it 'looks up profile from urn in content type' do
        content_type_with_profile = "#{content_type}; profile=#{profile_urn}"

        result, extensions = ResourceMapper.for(
          content_type: content_type_with_profile
        )

        _(result).must_equal class_with_profile
        _(extensions).must_equal []
      end

      it 'looks up profile from link header' do
        headers = { 'Link' => "<#{profile_url}>; rel=\"profile\"" }

        result, extensions = ResourceMapper.for(content_type: content_type, headers: headers)

        _(result).must_equal class_with_profile
        _(extensions).must_equal []
      end

      it 'looks up profile from payload link' do
        result, extensions = ResourceMapper.for(content_type: content_type, payload: payload)

        _(result).must_equal class_with_profile
        _(extensions).must_equal []
      end
    end

    describe 'extensions by looking up profile' do
      let(:stubs) { client.stubs }

      before do
        stubs.get(profile_url) do
          [200, {'Content-Type' => ShafClient::MIME_TYPE_ALPS_JSON}, alps_profile]
        end

        stubs.put('the/publishing/url') do
          [200, {'Content-Type' => 'text/plain'}, 'published!']
        end
      end

      it 'returns registered extensions' do
        ResourceMapper.unregister(content_type, profile_url)
        content_type_with_profile = "#{content_type}; profile=#{profile_url}"

        result, extensions = ResourceMapper.for(
          content_type: content_type_with_profile,
          payload: payload,
          client: client
        )

        _(result).must_equal clazz
        _(extensions.size).must_equal 1
        _(extensions.first).must_be_kind_of Module

        obj = result.new(client, payload, 200, {'Content-Type' => ShafClient::MIME_TYPE_HAL})
        obj.extend extensions.first

        publish_response = obj.publish!
        _(publish_response.body).must_equal 'published!'
        _(extensions.first.instance_method(:publish!)).wont_be_nil
      end
    end
  end
end
