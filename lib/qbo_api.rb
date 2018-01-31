require 'qbo_api/version'
require 'json'
require 'uri'
require 'securerandom'
require 'logger'
require 'faraday'
require 'faraday_middleware'
require 'faraday/detailed_logger'
require_relative 'qbo_api/configuration'
require_relative 'qbo_api/supporting'
require_relative 'qbo_api/error'
require_relative 'qbo_api/raise_http_exception'
require_relative 'qbo_api/entity'
require_relative 'qbo_api/util'
require_relative 'qbo_api/attachment'
require_relative 'qbo_api/setter'
require_relative 'qbo_api/builder'
require_relative 'qbo_api/finder'
require_relative 'qbo_api/all'

class QboApi
  extend Configuration
  include Supporting
  include Entity
  include Util
  include Attachment
  include Setter
  include Builder
  include Finder
  include All

  attr_reader :realm_id

  REQUEST_TOKEN_URL          = 'https://oauth.intuit.com/oauth/v1/get_request_token'
  ACCESS_TOKEN_URL           = 'https://oauth.intuit.com/oauth/v1/get_access_token'
  APP_CENTER_BASE            = 'https://appcenter.intuit.com'
  APP_CENTER_URL             =  APP_CENTER_BASE + '/Connect/Begin?oauth_token='
  V3_ENDPOINT_BASE_URL       = 'https://sandbox-quickbooks.api.intuit.com/v3/company/'
  PAYMENTS_API_BASE_URL      = 'https://sandbox.api.intuit.com/quickbooks/v4/payments'
  APP_CONNECTION_URL         = APP_CENTER_BASE + '/api/v1/connection'

  def initialize(token: nil, token_secret: nil, access_token: nil, realm_id:,
                 consumer_key: nil, consumer_secret: nil, endpoint: :accounting)
    @consumer_key = consumer_key || (defined?(CONSUMER_KEY) ? CONSUMER_KEY : nil)
    @consumer_secret = consumer_secret || (defined?(CONSUMER_SECRET) ? CONSUMER_SECRET : nil)
    @token = token
    @token_secret = token_secret
    @access_token = access_token
    @realm_id = realm_id
    @endpoint = endpoint
  end

  def connection(url: get_endpoint)
    @connection ||= Faraday.new(url: url) do |faraday|
      faraday.headers['Content-Type'] = 'application/json;charset=UTF-8'
      faraday.headers['Accept'] = 'application/json'
      if @token != nil
        faraday.request :oauth, oauth_data
      elsif @access_token != nil
        faraday.request :oauth2, @access_token, token_type: 'bearer'
      else
        raise QboApi::Error.new error_body: 'Must set either the token or access_token'
      end
      faraday.request :url_encoded
      faraday.use FaradayMiddleware::RaiseHttpException
      faraday.response :detailed_logger, QboApi.logger if QboApi.log
      faraday.adapter  Faraday.default_adapter
    end
  end

  def create(entity, payload:, params: nil)
    request(:post, entity: entity, path: entity_path(entity), payload: payload, params: params)
  end

  def update(entity, id:, payload:, params: nil)
    payload.merge!(set_update(entity, id))
    request(:post, entity: entity, path: entity_path(entity), payload: payload, params: params)
  end

  def delete(entity, id:)
    err_msg = "Delete is only for transaction entities. Use .deactivate instead"
    raise QboApi::NotImplementedError.new, err_msg unless is_transaction_entity?(entity)
    path = add_params_to_path(path: entity_path(entity), params: { operation: :delete })
    payload = set_update(entity, id)
    request(:post, entity: entity, path: path, payload: payload)
  end

  def deactivate(entity, id:)
    err_msg = "Deactivate is only for name list entities. Use .delete instead"
    raise QboApi::NotImplementedError.new, err_msg unless is_name_list_entity?(entity)
    payload = set_deactivate(entity, id)
    request(:post, entity: entity, path: entity_path(entity), payload: payload)
  end

  # https://developer.intuit.com/docs/0100_quickbooks_online/0100_essentials/0085_develop_quickbooks_apps/0004_authentication_and_authorization/oauth_management_api#/Reconnect
  def disconnect
    path = "#{APP_CONNECTION_URL}/disconnect"
    request(:get, path: path)
  end

  def reconnect
    path = "#{APP_CONNECTION_URL}/reconnect"
    request(:get, path: path)
  end

  def request(method, path:, entity: nil, payload: nil, params: nil)
    raw_response = connection.send(method) do |req|
      path = finalize_path(path, method: method, params: params)
      case method
      when :get, :delete
        req.url path
      when :post, :put
        req.url path
        req.body = payload.to_json
      end
    end
    response(raw_response, entity: entity)
  end

  def response(resp, entity: nil)
    data = JSON.parse(resp.body)
    if entity
      entity_response(data, entity)
    else
      data
    end
  rescue => e
    # Catch fetch key errors and just return JSON
    data
  end

  private

  def entity_response(data, entity)
    if qr = data['QueryResponse']
      qr.empty? ? nil : qr.fetch(singular(entity))
    elsif ar = data['AttachableResponse']
      ar.first.fetch(singular(entity))
    else
      data.fetch(singular(entity))
    end
  end

  def oauth_data
    {
      consumer_key: @consumer_key,
      consumer_secret: @consumer_secret,
      token: @token,
      token_secret: @token_secret
    }
  end

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
