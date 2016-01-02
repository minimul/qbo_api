require 'qbo_api/version'
require 'json'
#require 'rack'
require 'logger'
require 'faraday'
require 'faraday_middleware'
require 'faraday/detailed_logger'
require_relative 'qbo_api/configuration'
require_relative 'qbo_api/error'
require_relative 'qbo_api/raise_http_exception'
require_relative 'qbo_api/entity'

class QboApi
  extend Configuration
  include Entity
  attr_reader :realm_id

  REQUEST_TOKEN_URL          = 'https://oauth.intuit.com/oauth/v1/get_request_token'
  ACCESS_TOKEN_URL           = 'https://oauth.intuit.com/oauth/v1/get_access_token'
  APP_CENTER_BASE            = 'https://appcenter.intuit.com'
  APP_CENTER_URL             =  APP_CENTER_BASE + '/Connect/Begin?oauth_token='
  V3_ENDPOINT_BASE_URL       = 'https://sandbox-quickbooks.api.intuit.com/v3/company/'
  PAYMENTS_API_BASE_URL      = 'https://sandbox.api.intuit.com/quickbooks/v4/payments'
  APP_CONNECTION_URL         = APP_CENTER_BASE + '/api/v1/connection'

  def initialize(token:, token_secret:, realm_id:, consumer_key: CONSUMER_KEY, 
                 consumer_secret: CONSUMER_SECRET, endpoint: :accounting)
    @consumer_key = consumer_key
    @consumer_secret = consumer_secret
    @token = token
    @token_secret = token_secret
    @realm_id = realm_id
    @endpoint = endpoint
  end

  def connection(url: get_endpoint)
    Faraday.new(url: url) do |faraday|
      faraday.headers['Content-Type'] = 'application/json;charset=UTF-8'
      faraday.headers['Accept'] = "application/json"
      faraday.request :oauth, oauth_data 
      faraday.request :url_encoded
      faraday.use FaradayMiddleware::RaiseHttpException
      faraday.response :detailed_logger, QboApi.logger if QboApi.log
      faraday.adapter  Faraday.default_adapter
    end
  end

  def query(query)
    path = "#{realm_id}/query?query=#{query}"
    entity = extract_entity_from_query(query, to_sym: true)
    request(:get, entity: entity, path: path)
  end

  def get(entity, id)
    path = "#{realm_id}/#{entity.to_s}/#{id}"
    request(:get, entity: entity, path: path)
  end

  def create(entity, payload:)
    path = "#{realm_id}/#{entity}"
    request(:post, entity: entity, path: path, payload: payload)
  end

  def update(entity, id:, payload:)
    path = "#{realm_id}/#{entity}"
    payload.merge!(set_update(entity, id))
    request(:post, entity: entity, path: path, payload: payload)
  end

  def delete(entity, id:)
    raise QboApi::NotImplementedError unless is_transaction_entity?(entity)
    path = "#{realm_id}/#{entity}?operation=delete"
    payload = set_update(entity, id)
    request(:post, entity: entity, path: path, payload: payload)
  end

  # TODO: Need specs for disconnect and reconnect
  # https://developer.intuit.com/docs/0100_accounting/0060_authentication_and_authorization/oauth_management_api
  def disconnect
    response = connection(url: APP_CONNECTION_URL).get('/disconnect')
  end

  def reconnect
    response = connection(url: APP_CONNECTION_URL).get('/reconnect')
  end

  def all(entity, max: 1000, select: nil, &block)
    select ||= "SELECT * FROM #{singular(entity)}"
    pos = 0
    begin
      pos = pos == 0 ? pos + 1 : pos + max
      results = query("#{select} MAXRESULTS #{max} STARTPOSITION #{pos}")
      results.each do |entry|
        yield(entry)
      end if results
    end while (results ? results.size == max : false)
  end

  def request(method, entity:, path:, payload: nil)
    raw_response = connection.send(method) do |req|
      case method
      when :get, :delete
        req.url URI.encode(path)
      when :post, :put
        req.url path
        req.body = JSON.generate(payload)
      end
    end
    response(raw_response, entity: entity)
  end

  def response(resp, entity: nil)
    j = JSON.parse(resp.body)
    if entity
      if qr = j['QueryResponse']
        qr.empty? ? nil : qr.fetch(singular(entity))
      else
        j.fetch(singular(entity))
      end
    else
      j
    end
  rescue => e
    # Catch fetch key errors and just return JSON
    j
  end

  def esc(query)
    query.gsub("'", "\\\\'")
  end

  private

  def oauth_data
    {
      consumer_key: @consumer_key,
      consumer_secret: @consumer_secret,
      token: @token,
      token_secret: @token_secret
    }
  end

  def set_update(entity, id)
    resp = get(entity, id)
    { Id: resp['Id'], SyncToken: resp['SyncToken'] }
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
