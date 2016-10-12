$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'qbo_api'
require 'rspec'
require 'webmock/rspec'
require 'vcr'
require 'awesome_print'
require_relative 'support/credentials'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("../vcr", __FILE__)
  config.hook_into :webmock
  config.filter_sensitive_data('<ACCESS_TOKEN>') { URI.encode_www_form_component(creds.token) }
  config.filter_sensitive_data('<CONSUMER_KEY>') { URI.encode_www_form_component(creds.consumer_key) }
  config.filter_sensitive_data('<COMPANY_ID>') { URI.encode_www_form_component(creds.realm_id) }
  
  uri_matcher = VCR.request_matchers[:uri]
  # Don't check sandbox company id or trailing URL id
  # This enables multiple different sandboxes to be used
  # in testing
  config.register_request_matcher(:for_intuit) do |req_1, req_2|
    uri1, uri2 = req_1.uri, req_2.uri
    if uri1 =~ /intuit\.com/ && uri2 =~ /intuit\.com/
      strip_url_company_id(req_1.uri, req_2.uri)
      strip_request_id_value(req_1.uri, req_2.uri)
      regexp_trail_id = %r(/\d+/?\z)
      if uri1.match(regexp_trail_id)
        r1_without_id = uri1.gsub(regexp_trail_id, "")
        r2_without_id = uri2.gsub(regexp_trail_id, "")
        uri1.match(regexp_trail_id) && uri2.match(regexp_trail_id) && r1_without_id == r2_without_id
      else
        uri_matcher.matches?(req_1, req_2)
      end
    else
      uri_matcher.matches?(req_1, req_2)
    end
  end

  def strip_url_company_id(*args)
    regexp_company_id = %r((company)/\d+/?)
    args.each do |ref|
      ref.sub!(regexp_company_id, '')
    end
  end

  def strip_request_id_value(*args)
    regexp = %r(requestid=(.*?)$)
    args.each do |ref|
      m = ref.match(regexp)
      ref.sub!(m[1], '') if m
    end
  end

  config.default_cassette_options = { match_requests_on: [:method, :for_intuit] }
end


RSpec.configure do |config|
end

def endpoint
  QboApi::V3_ENDPOINT_BASE_URL
end

def a_delete(path)
  a_request(:delete, endpoint + path)
end

def a_get(path)
  a_request(:get, endpoint + path)
end

def a_post(path)
  a_request(:post, endpoint + path)
end

def a_put(path)
  a_request(:put, endpoint + path)
end

def stub_delete(path)
  stub_request(:delete, endpoint + path)
end

def stub_get(path)
  stub_request(:get, endpoint + path)
end

def stub_post(path)
  stub_request(:post, endpoint + path)
end

def stub_put(path)
  stub_request(:put, endpoint + path)
end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end
