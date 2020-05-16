# Shaf Client
[![Gem Version](https://badge.fury.io/rb/shaf_client.svg)](https://badge.fury.io/rb/shaf_client)
[![Build Status](https://travis-ci.org/sammyhenningsson/shaf_client.svg?branch=master)](https://travis-ci.org/sammyhenningsson/shaf_client)  
ShafClient is simple [HAL](http://stateless.co/hal_specification.html) client with a few customizations for APIs built with [Shaf](https://github.com/sammyhenningsson/shaf).

## Installation
```sh
gem install shaf_client
```
Or put `gem 'shaf_client'` in your Gemfile and run `bundle install`


## Usage
Create an instance of `ShafClient` with a uri to the API entry point. Then call `get_root` on the returned client to get back a `ShafClient::Resource` and start interacting with the API.
```ruby
client = ShafClient.new('https://my.hal_api.com/')
root = client.get_root
```

Instances of `ShafClient::Resource` respond to the following methods:
 - `#attributes`                            - Returns a hash of all attributes
 - `#links`                                 - Returns a hash of all links
 - `#curies`                                - Returns a hash of all curies
 - `#embedded_resources`                    - Returns a hash of all embedded resources
 - `#attribute(key)`                        - Returns the value for the attribute with the given _key_
 - `#link(rel)`                             - Returns a `ShafClient::Link` for the given _rel_
 - `#curie(rel)`                            - Returns a `ShafClient::Curie` for the given _rel_
 - `#embedded(rel)`                         - Returns a `ShafClient::BaseResource` for the given _rel_
 - `#[](key)`                               - Alias for `attribute(key)`
 - `#actions`                               - Returns a list of all links relations
 - `#to_s`                                  - Returns a `String` representation
 - `#inspect`                               - Returns a detailed `String` representation
 - `#get(rel, **options)`                   - Performs a GET request to the href of the link with rel _rel_
 - `#put(rel, payload: nil, **options)`     - Performs a PUT request to the href of the link with rel _rel_
 - `#post(rel, payload: nil, **options)`    - Performs a POST request to the href of the link with rel _rel_
 - `#delete(rel, payload: nil, **options)`  - Performs a DELETE request to the href of the link with rel _rel_
 - `#patch(rel, payload: nil, **options)`   - Performs a PATCH request to the href of the link with rel _rel_
 - `#get_doc(rel)`                          - Retrieves the documentation for a _rel_ by looking up its curie
 - `#get_hal_form(rel)`                     - Retrieves a form by performing a GET request on the value of _rel_.
 - `#rel?(rel)`                             - Returns true if the resource has a link with rel _rel_
 - `#reload!`                               - Refresh itself by fetching the _self_ link (by-passing cache)
 - `#destroy!`                              - Performs a DELETE request to the href of the link with rel _delete_
 - `#http_status`                           - The response HTTP status returned by the server
 - `#headers`                               - The response HTTP headers returned by the server

Instances of `ShafClient` respond to the following methods:
 - `#get_root(**options)`                   - Performs a GET request to the root_uri (first arg to #initialize)
 - `#head(uri, **options)`                  - Performs a HEAD request to the given uri
 - `#get(uri, **options)`                   - Performs a GET request to the given uri
 - `#put(uri, payload, **options)`          - Performs a PUT request to the given uri
 - `#post(uri, payload, **options)`         - Performs a POST request to the given uri
 - `#delete(uri, payload, **options)`       - Performs a DELETE request to the given uri
 - `#patch(uri, payload, **options)`        - Performs a PATCH request to the given uri
 - `#stubs`                                 - Only used for testing

## Examples
```ruby
require 'shaf_client'
client = ShafClient.new('http://localhost:3000')
root = client.get_root      # Equivalent to client.get('http://localhost:3000')
root.headers                # => {"content-type"=>"application/hal+json", "cache-control"=>"private, max-age=20"…
root = client.get_root      # Returns same response as above, except this time no network request is performed. A cached                                 # response is returned instead
root.actions                # => [:self, :posts, :comments]

posts = root.get(:posts)
posts.embedded_resources    # => {:posts=>[#<ShafClient::BaseResource:0x00005615723cad10 @payload…
posts.embedded(:posts)      # Returns an array of `ShafClient::BaseResource` instances
posts.actions               # => [:self, :up, :"doc:create-form"]
form = posts.get("doc:create-form") # this assumes that Content-Type contains the profile 'shaf-form'.
                                    # it's also possible to type: posts.get("create-form") or posts.get(:create_form)
form.headers                # => {"content-type"=>"application/hal+json;profile=shaf-form", "cache-control"=>"private, max-age=3600", "etag"=>"W/\"83ef6d28f4b81f8f9ceae17f5f8a42d6dedfff73\"…"}
form.class                  # => ShafClient::ShafForm
form.values                 # => {:title=>nil, :message=>nil}
form.valid?                 # => false
form[:title] = "hello"
form[:message] = "world"
created_post = form.submit  # Returns a new `ShafClient::Resource`

created_post.attributes     # => {:title=>"hello", :message=>"world"}
created_post.actions        # => [:"collection", :self, :"edit-form", :"doc:delete"]
puts created_post.to_s      # => {
                            #      "title": "hello",
                            #      "message": "world",
                            #      "_links": {
                            #        "collection": {
                            #          "href": "http://localhost:3000/posts",
                            #          "title": "up"
                            #        },
                            #        "self": {
                            #          "href": "http://localhost:3000/posts/1"
                            #        },
                            #        "edit-form": {
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

created_post.link(:self).href      # => "http://localhost:3000/posts/1"

delete_doc = created_post.get_doc("doc:delete")
puts delete_doc.actions     # => [:self, :up]
puts delete_doc.attribute(:delete) # => Link to delete this post.
                                   #    Method: DELETE
                                   #    Example:
                                   #    
                                   #    curl -H "Accept: application/hal+json" \
                                   #         -H "Authorization: abcdef \"
                                   #         -X DELETE \
                                   #         /posts/5


# Request headers can be given to #get, #put, etc throught the headers keyword argument
problem_json = client.get('http://localhost:3000/idonotexist', headers: {'Accept' => 'application/problem+json'})
puts problem_json.content_type    # => application/problem+json
puts problem_json
                                  # => {
                                  #      "status": 404,
                                  #      "type": "about:blank",
                                  #      "title": "Not Found",
                                  #      "detail": "Resource \"/idonotexist\" does not exist"
                                  #    }


```

## Adding semantic meaning to resources
Note the form in the example above. `form` is an instance of `ShafClient::ShafForm` (which is a subclass of `ShafClient::Form` which in turn is a subclass of `ShafClient::Resource`).
Forms have a few extra methods that makes it easy to fill in values and submitting them. The reason that we received an instance of `ShafClient::ShafForm` rather than `ShafClient::Resource` is that the server responded with the Content-Type `application/hal+json;profile=shaf-form`. The [shaf-form](https://gist.github.com/sammyhenningsson/39c8aafeaf60192b082762cbf3e08d57) profile describes the semantic meaning of this representation and luckily ShafClient knowns about this profile.  
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
Instances of `ShafClient::Form` respond to the following methods:
 - `#values`                        - Returns a hash of the form inputs
 - `#[](key)`                       - Returns the value of a given input
 - `#[]=(key, value)`               - Sets the value of a given input
 - `#title`                         - Returns the title of the form
 - `#target`                        - Returns the target href (where the form will be submitted to)
 - `#http_method`                   - Returns the HTTP method to be used when submitting the form
 - `#content_type`                  - Returns the content type used when the form is submitted
 - `#submit`                        - Submit the form
 - `#valid?`                        - Returns `true` if client side validations pass. Otherwise `false`

## HAL-FORMS
ShafClient also support forms presented using the [HAL-FORMS](https://rwcbook.github.io/hal-forms/) mediatype.
The workflow using `HAL-FORMS` differs a bit from `shaf-forms` and requires the client to intentionally request a form. For this, the method `#get_hal_form(rel)` is used.
The returned object is an instance of `ShafClient::HalForm` (which is a subclass of `ShafClient::Form`). So submitting the form follows the same flow as shown above. 
The `rel` given to `#get_hal_form(rel)` may be compacted with a curie. In that case it will be "expanded" before the GET request is performed.

## Non HAL responses
Of course, not all responses will be formatted as HAL. Whenever the response body is empty an instance of `ShafClient::EmptyResource` is returned.
If the Content-Type cannot be understood an instance of `ShafClient::UnknownResource` is returned.
These two classes also inherit from `ShafClient::Resource` so all the usual methods are still available (though most of them return `nil`, `""`, `{}` or `[]`).
Instances of `ShafClient::UnknownResource` also has a`#body` method. `#body`, `#http_status` and `#headers` are basically the only usefull methods for those instances.
Problem Json responses will return instances of `ShafClient::ProblemJson` (see example above).

## Authentication
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

## Faraday
ShafClient wraps the [faraday](https://github.com/lostisland/faraday) gem. By default it uses the `Net::HTTP` adapter. To use another adapter pass in the corresponding symbol in the `:faraday_adapter` when instantiating the client. (Note: make sure to install and require corresponding dependencies.)
```ruby
client = ShafClient.new('https://my.hal_api.com/', faraday_adapter: :net_http_persistent)
```

## HTTP cache
ShafClient supports HTTP caching by using the [faraday-http-cache](https://github.com/plataformatec/faraday-http-cache), Faraday middleware.
This means that if the server returns responses with caching directives (e.g. `Cache-Control`, `Etag` etc), those responses are properly cached. And no unnecessary request will be made when a valid cache entry exist.
To pass down options to faraday-http-cache (e.g a cache store) pass them to ShafClient as options under the `:faraday_http_cache` key.
```ruby
store = ActiveSupport::Cache.lookup_store(:mem_cache_store, ['localhost:11211'])
client = ShafClient.new('https://my.hal_api.com/', faraday_http_cache: {store: store})
```

## Hypertext Cache Pattern
Servers may preload resources (by embedded them) in hope of increasing the api performance. See [Hypertext Cache Pattern](https://tools.ietf.org/html/draft-kelly-json-hal-08#section-8.3) for more info.
An application using ShafClient, might have a "hard coded" workflow where it always fetches posts and then their authors. E.g.
```ruby
post = client.get(some_post_uri)
author = post.get(:author)
```
Normally this would result in two requests to the server. However if the API server decides that the client probably also want the corresponding author resource (which normally is just linked to but not embedded), it may embedded the _author_ resource in the _post_ response. In this case ShafClient will only make one request and simply return the embedded _author_ on the second line above.
This adds great flexibility for servers to dynamically change the responses to increase performance.  
However this may cause problems if the embedded resource should not be interpreted as application/hal+json (i.e. plain HAL without any extensions).
ShafClient has three settings for how to handle this:
 1. Ignore embedded resources and refetch them through the link relation.
 2. Return the embedded resource (as regular HAL resource).
 3. Perform a HEAD request and return the resource with correct headers.

This can be configured globally by calling `ShafClient.default_hypertext_cache_strategy=(strategy)`. Where strategy is one of (Note: same order as above):
 1. `:no_cache`
 2. `:use_embedded`
 3. `:fetch_headers`

It can also be configured per request, by using the `hypertext_cache_strategy` option. E.g.
```ruby
post.get(:author, hypertext_cache_strategy: :fetch_headers)
```

## Example API
If you would like to try out ShafClient but don't yet have a HAL API, then an example api, created with [Shaf](https://github.com/sammyhenningsson/shaf), can be found [here](https://shaf-blog-demo.herokuapp.com/).
```ruby
client = ShafClient.new("https://shaf-blog-demo.herokuapp.com/")
…
```

## Redirects
ShafClient will automatically follow redirects.  

## Contributing
If you find a bug or have suggestions for improvements, please create a new issue on Github. Pull request are welcome!
As usual: Fork, commit changes to a new branch, open a pull request!  

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
