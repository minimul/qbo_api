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

  attr_accessor :realm_id
  attr_accessor :endpoint

  V3_ENDPOINT_BASE_URL       = 'https://sandbox-quickbooks.api.intuit.com/v3/company/'
  PAYMENTS_API_BASE_URL      = 'https://sandbox.api.intuit.com/quickbooks/v4/payments'
  LOG_TAG = "[QuickBooks]"

  # @param attributes [Hash<Symbol,String>]
  def initialize(attributes = {})
    raise ArgumentError, "missing keyword: realm_id" unless attributes.key?(:realm_id)
    attributes = default_attributes.merge!(attributes)
    attributes.each do |attribute, value|
      public_send("#{attribute}=", value)
    end
    @endpoint_url = get_endpoint
  end

  def default_attributes
    {
      endpoint: :accounting
    }
  end

  def connection(url: endpoint_url)
    @connection ||= authorized_json_connection(url)
  end

  def endpoint_url
    @endpoint_url.dup
  end

  private

  def get_endpoint
    prod = self.class.production
    {
      accounting: prod ? V3_ENDPOINT_BASE_URL.sub("sandbox-", '') : V3_ENDPOINT_BASE_URL,
      payments: prod ? PAYMENTS_API_BASE_URL.sub("sandbox.", '') : PAYMENTS_API_BASE_URL
    }.fetch(endpoint) do
      raise KeyError, "Invalid endpoint: #{endpoint.inspect}"
    end
  end
end
