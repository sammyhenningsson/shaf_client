# Shaf Client
[![Gem Version](https://badge.fury.io/rb/shaf_client.svg)](https://badge.fury.io/rb/shaf_client)
[![Build Status](https://travis-ci.org/sammyhenningsson/shaf_client.svg?branch=master)](https://travis-ci.org/sammyhenningsson/shaf_client)  
ShafClient is simple [HAL](http://stateless.co/hal_specification.html) client with a few customizations for APIs built with [Shaf](https://github.com/sammyhenningsson/shaf).

## Installation
```sh
gem install shaf_client
```
Or put `gem 'shaf_client'` in your Gemfile and run `bundle install`


# Usage
Create an instance of `ShafClient` with a uri to the API entry point. Then call `get_root` on the returned client to start interacting with the API and get back a `ShafClient::Resource`.
```ruby
client = ShafClient.new('https://my.hal_api.com/')
root = client.get_root
```

Instances of `ShafClient::Resource` respond to the following methods:
 - `#attributes`                    - Returns a hash of all attributes
 - `#links`                         - Returns a hash of all links
 - `#curies`                        - Returns a hash of all curies
 - `#embedded_resources`            - Returns a hash of all embedded resources
 - `#attribute(key)`                - Returns the value for attribute with key _key_
 - `#link(rel)`                     - Returns `ShafClient::Link` for the given _rel_
 - `#curie(rel)`                    - Returns `ShafClient::Curie` for the given _rel_
 - `#embedded(rel)`                 - Returns `ShafClient::BaseResource` for the given _rel_
 - `#[](key)`                       - Alias for `attribute(key)`
 - `#actions`                       - Returns a list of all links relations
 - `#to_s`                          - Returns a `String` representation
 - `#get(rel)`                      - Performs a GET request to the href of the link with rel _rel_
 - `#put(rel, payload: nil)`        - Performs a PUT request to the href of the link with rel _rel_
 - `#post(rel, payload: nil)`       - Performs a POST request to the href of the link with rel _rel_
 - `#delete(rel, payload: nil)`     - Performs a DELETE request to the href of the link with rel _rel_
 - `#patch(rel, payload: nil)`      - Performs a PATCH request to the href of the link with rel _rel_
 - `#get_doc(rel)`                  - Retrieves the documentation for a _rel_ by looking up its curie
 - `#rel?(rel)`                     - Returns true if the resource has a link with rel _rel_
 - `#reload!`                       - Refresh itself by fetching the _self_ link (by-passing cache)
 - `#destroy!`                      - Performs a DELETE request to the href of the link with rel _delete_
 - `#http_status`                   - The response HTTP status returned by the server
 - `#headers`                       - The response HTTP headers returned by the server


# Examples
```ruby
require 'shaf_client'
client = ShafClient.new('http://localhost:3000')
root = client.get_root
root.actions                # => [:self, :posts, :comments]
root.headers                # => {"content-type"=>"application/hal+json", "cache-control"=>"private, max-age=20"…

posts = root.get(:posts)
posts.actions               # => [:self, :up, :"doc:create-form"]
posts.embedded_resources    # => {:posts=>[#<ShafClient::BaseResource:0x00005615723cad10 @payload…
posts.embedded(:posts)      # Returns an array of `ShafClient::BaseResource` instances

form = posts.get("doc:create-form") # this assumes that Content-Type contains the profile 'shaf-form'.
                                    # it's also possible to type: posts.get("create-form") or posts.get(:create_form)
form.class                  # => ShafClient::Form
form.values                 # => {:title=>nil, :message=>nil}
form.valid?                 # => false
form[:title] = "hello"
form[:message] = "world"
created_post = form.submit  # Returns a new `ShafClient::Resource`


created_post.attributes     # => {:title=>"hello", :message=>"world"}
created_post.actions        # => [:"doc:up", :self, :"doc:edit-form", :"doc:delete"]
puts created_post.to_s      # => {
                            #      "title": "hello",
                            #      "message": "world",
                            #      "user_id": 1,
                            #      "_links": {
                            #        "doc:up": {
                            #          "href": "http://localhost:3000/posts",
                            #          "title": "up"
                            #        },
                            #        "self": {
                            #          "href": "http://localhost:3000/posts/1"
                            #        },
                            #        "doc:edit-form": {
                            #          "href": "http://localhost:3000/posts/1/edit",
                            #          "title": "edit"
                            #        },
                            #        "doc:delete": {
                            #          "href": "http://localhost:3000/posts/1",
                            #          "title": "delete"
                            #        },
                            #        "curies": [
                            #          {
                            #            "name": "doc",
                            #            "href": "http://localhost:3000/doc/post/rels/{rel}",
                            #            "templated": true
                            #          }
                            #        ]
                            #      }
                            #    }


```

# Adding semantic meaning to resources
Note the form in the example above. `form` is an instance of `ShafClient::Form` (which is a subclass of `ShafClient::Resource`).
It has a few extra methods that makes it easy to fill in the form and submit it. The reason that we received an instance of `ShafClient::Form` rather than `ShafClient::Resource` is that the server responded with the Content-Type `application/hal+json;profile=shaf-form`. The [shaf-form](https://gist.github.com/sammyhenningsson/39c8aafeaf60192b082762cbf3e08d57) profile describes the semantic meaning of this representation and luckily ShafClient knowns about this profile.  
Adding support for other profiles is as simple as creating a subclass of `ShafClient::Resource` and call the class method `profile` with the name of your profile. So say that you have a server that returns a response with Content-Type: `application/hal+json;profile=foobar`. Then you could do something like this:
```ruby
class CustomResource < ShafClient::Resource
  profile 'foobar'

  def attr_string
    attributes.keys.join('_')
  end
end

foobar = client.get_root.get(:some_rel_returning_foobar)
foobar.class            # => CustomResource
foobar.attr_string      # => "key1_key2_key3"
```
Note: This only serves the purpose of understanding how this works :)

# Authentication
ShafClient supports basic auth and token based authentication.  
For Basic Auth, pass keyword arguments `:user` and `password` when instantiating the client.
```ruby
client = ShafClient.new('https://my.hal_api.com/', user: "alice", password: "ecila")
```
For Token based authentication, pass keyword argument `:auth_token` when instantiating the client. This will send the token in the `X-Auth-Token` header. To use another header, set it with the keyword argument `:auth_header`.
```ruby
client = ShafClient.new('https://my.hal_api.com/', auth_token: "Ohd2quet")
# or
client = ShafClient.new('https://my.hal_api.com/', auth_token: "Ohd2quet", auth_header: "Authorization")
```

# Faraday
ShafClient wraps the [faraday](https://github.com/lostisland/faraday) gem. By default it uses the `Net::HTTP` adapter. To use another adapter pass in the corresponding symbol in the `:faraday_adapter` when instantiating the client. (Note: make sure to install and require corresponding dependencies.)
```ruby
client = ShafClient.new('https://my.hal_api.com/', faraday_adapter: :net_http_persistent)
```

# HTTP cache
ShafClient supports HTTP caching by using the [faraday-http-cache](https://github.com/plataformatec/faraday-http-cache), Faraday middleware.
This means that if the server returns responses with caching directives (e.g. `Cache-Control`, `Etag` etc), those responses are properly cached. And no unnecessary request will be made when a valid cache entry exist.
To pass down options to faraday-http-cache (e.g a cache store) pass them to ShafClient as options under the `:faraday_http_cache` key.
```ruby
store = ActiveSupport::Cache.lookup_store(:mem_cache_store, ['localhost:11211'])
client = ShafClient.new('https://my.hal_api.com/', faraday_http_cache: {store: store})
```

# Redirects
ShafClient will automatically follow redirects.  

## Contributing
If you find a bug or have suggestions for improvements, please create a new issue on Github. Pull request are welcome!
As usual: Fork, commit changes to a new branch, open a pull request!  

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
