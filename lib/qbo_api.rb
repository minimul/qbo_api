require 'qbo_api/version'
require 'json'
require 'uri'
require 'securerandom'
require 'logger'
require_relative 'qbo_api/configuration'
require_relative 'qbo_api/connection'
require_relative 'qbo_api/supporting'
require_relative 'qbo_api/error'
require_relative 'qbo_api/raise_http_exception'
require_relative 'qbo_api/entity'
require_relative 'qbo_api/util'
require_relative 'qbo_api/attachment'
require_relative 'qbo_api/api_methods'

class QboApi
  extend Configuration
  include Connection
  include Supporting
  include Entity
  include Util
  include Attachment
  include ApiMethods

  attr_accessor :token, :token_secret
  attr_accessor :access_token
  attr_accessor :realm_id
  attr_accessor :consumer_key, :consumer_secret
  attr_accessor :endpoint

  REQUEST_TOKEN_URL          = 'https://oauth.intuit.com/oauth/v1/get_request_token'
  ACCESS_TOKEN_URL           = 'https://oauth.intuit.com/oauth/v1/get_access_token'
  APP_CENTER_BASE            = 'https://appcenter.intuit.com'
  APP_CENTER_URL             =  APP_CENTER_BASE + '/Connect/Begin?oauth_token='
  V3_ENDPOINT_BASE_URL       = 'https://sandbox-quickbooks.api.intuit.com/v3/company/'
  PAYMENTS_API_BASE_URL      = 'https://sandbox.api.intuit.com/quickbooks/v4/payments'
  APP_CONNECTION_URL         = APP_CENTER_BASE + '/api/v1/connection'
  LOG_TAG = "[QuickBooks]"

  # @param attributes [Hash<Symbol,String>]
  def initialize(attributes = {})
    raise ArgumentError, "missing keyword: realm_id" unless attributes.key?(:realm_id)
    attributes = default_attributes.merge!(attributes)
    attributes[:consumer_key] ||= (defined?(CONSUMER_KEY) ? CONSUMER_KEY : nil)
    attributes[:consumer_secret] ||=(defined?(CONSUMER_SECRET) ? CONSUMER_SECRET : nil)
    attributes.each do |attribute, value|
      public_send("#{attribute}=", value)
    end
    @endpoint_url = get_endpoint
  end

  def default_attributes
    {
      token: nil, token_secret: nil, access_token: nil,
      consumer_key: nil, consumer_secret: nil, endpoint: :accounting
    }
  end

  def connection(url: @endpoint_url)
    @connection ||= authorized_json_connection(url)
  end

  private

  def get_endpoint
    prod = self.class.production
    case @endpoint
    when :accounting
      prod ? V3_ENDPOINT_BASE_URL.sub("sandbox-", '') : V3_ENDPOINT_BASE_URL
    when :payments
      prod ? PAYMENTS_API_BASE_URL.sub("sandbox.", '') : PAYMENTS_API_BASE_URL
    end
  end
end
