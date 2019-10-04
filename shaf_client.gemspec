# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name        = 'shaf_client'
  gem.version     = '0.6.2'
  gem.summary     = "HAL client for Shaf"
  gem.description = "A HAL client customized for Shaf APIs"
  gem.authors     = ["Sammy Henningsson"]
  gem.email       = 'sammy.henningsson@gmail.com'
  gem.homepage    = "https://github.com/sammyhenningsson/shaf_client"
  gem.license     = "MIT"

  gem.cert_chain  = ['certs/sammyhenningsson.pem']
  gem.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/

  gem.files         = Dir['lib/**/*rb']
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.5'
  gem.add_runtime_dependency "faraday", '~> 0.15'
  gem.add_runtime_dependency "faraday-http-cache", '~> 2.0'
  gem.add_development_dependency "rake", '~> 12.0'
  gem.add_development_dependency "minitest", '~> 5', '>= 5.10'
end
