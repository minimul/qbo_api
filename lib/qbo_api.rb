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

  attr_reader :realm_id

  REQUEST_TOKEN_URL          = 'https://oauth.intuit.com/oauth/v1/get_request_token'
  ACCESS_TOKEN_URL           = 'https://oauth.intuit.com/oauth/v1/get_access_token'
  APP_CENTER_BASE            = 'https://appcenter.intuit.com'
  APP_CENTER_URL             =  APP_CENTER_BASE + '/Connect/Begin?oauth_token='
  V3_ENDPOINT_BASE_URL       = 'https://sandbox-quickbooks.api.intuit.com/v3/company/'
  PAYMENTS_API_BASE_URL      = 'https://sandbox.api.intuit.com/quickbooks/v4/payments'
  APP_CONNECTION_URL         = APP_CENTER_BASE + '/api/v1/connection'
  LOG_TAG = "[QuickBooks]"

  def initialize(token: nil, token_secret: nil, access_token: nil, realm_id:,
                 consumer_key: nil, consumer_secret: nil, endpoint: :accounting)
    @consumer_key = consumer_key || (defined?(CONSUMER_KEY) ? CONSUMER_KEY : nil)
    @consumer_secret = consumer_secret || (defined?(CONSUMER_SECRET) ? CONSUMER_SECRET : nil)
    @token = token
    @token_secret = token_secret
    @access_token = access_token
    @realm_id = realm_id
    @endpoint = endpoint
    @endpoint_url = get_endpoint
  end

  def connection(url: @endpoint_url)
    @connection ||= authorized_json_connection(url: url)
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
