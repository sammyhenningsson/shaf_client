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
 - `#get_form(rel)`                 - Like `get(rel)` but returns a `ShafClient::Form`(Shaf specific)
 - `#get_doc(rel)`                  - Retrieves the documentation for a _rel_ by looking up its curie
 - `#reload!`                       - Refresh itself by fetching the _self_ link (by-passing cache)
 - `#http_status`                   - The response HTTP status returned by the server
 - `#headers`                       - The response HTTP headers returned by the server


# Examples
```ruby
require 'shaf_client'
client = ShafClient.new('http://localhost:3000')
root = client.get_root
root.actions                # => [:self, :posts, :comments]

posts = root.get(:posts)
posts.actions               # => [:self, :up, :"doc:create-form"]
posts.embedded_resources    # => {:posts=>[#<ShafClient::BaseResource:0x00005615723cad10 @payload…
posts.embedded(:posts)      # Returns an array of `ShafClient::BaseResource` instances

form = posts.get("doc:create-form") # this assumes that Content-Type contains the profile 'shaf-form'. Otherwise use `#get_form`.
form.values                 # => {:title=>nil, :message=>nil}
form[:title] = "hello"
form[:message] = "world"
created_post = form.submit  # Returns a new `ShafClient::Resource`


created_post.attributes     # => {:title=>"hello", :message=>"world"}
created_post.actions        # => [:"doc:up", :self, :"doc:edit-form", :"doc:delete"]

```

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
ShafClient supports HTTP caching. This means that if the server returns responses with the header `Cache-Control` and/or `Etag`, those responses are cached. If a request is made and there is a valid entry in the cache it is returned directly instead of reaching out to the server. If there is an expired entry with an etag in the cache and a new request is made for the corresponding resources then the `If-None-Match` header is added with that etag. If the server then responds with 304 Not Modified, the cached payload is returned.  

# Redirects
ShafClient will automatically follow redirects.  

## Contributing
If you find a bug or have suggestions for improvements, please create a new issue on Github. Pull request are welcome!
As usual: Fork, commit changes to a new branch, open a pull request!  

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
