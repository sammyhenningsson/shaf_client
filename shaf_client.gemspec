# -*- encoding: utf-8 -*-
require './lib/shaf_client/version'

Gem::Specification.new do |gem|
  gem.name        = 'shaf_client'
  gem.version     = ShafClient::VERSION
  gem.summary     = "HAL client for Shaf"
  gem.description = "A HAL client customized for Shaf APIs"
  gem.authors     = ["Sammy Henningsson"]
  gem.email       = 'sammy.henningsson@gmail.com'
  gem.homepage    = "https://github.com/sammyhenningsson/shafClient"
  gem.license     = "MIT"
  # gem.metadata    = {
  #   "changelog_uri" => "https://github.com/sammyhenningsson/shaf_client/blob/master/CHANGELOG.md"
  # }

  gem.cert_chain  = ['certs/sammyhenningsson.pem']
  gem.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/

  gem.files         = Dir['lib/**/*rb']
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.5'
  gem.add_runtime_dependency "faraday", '~> 0.15'
end
