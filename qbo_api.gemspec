# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qbo_api/version'

Gem::Specification.new do |spec|
  spec.name          = "qbo_api"
  spec.version       = QboApi::VERSION
  spec.authors       = ["Christian Pelczarski"]
  spec.email         = ["christian@minimul.com"]

  spec.summary       = %q{Ruby JSON-only client for QuickBooks Online API v3. Built on top of the Faraday gem. }
  spec.homepage      = "https://github.com/minimul/qbo_api"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'sinatra'
  spec.add_development_dependency 'rack-oauth2'
  spec.add_development_dependency 'omniauth'
  spec.add_development_dependency 'omniauth-quickbooks'
  spec.add_development_dependency 'shotgun'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'awesome_print'
  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'faraday_middleware'
  spec.add_runtime_dependency 'faraday-detailed_logger'
  spec.add_runtime_dependency 'simple_oauth'
  spec.add_runtime_dependency 'nokogiri'
end
