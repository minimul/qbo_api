class QboApi
  APP_CENTER_BASE            = 'https://appcenter.intuit.com'
  APP_CENTER_URL             =  APP_CENTER_BASE + '/Connect/Begin?oauth_token='
  APP_CONNECTION_URL         = APP_CENTER_BASE + '/api/v1/connection'

  attr_accessor :token, :token_secret
  attr_accessor :consumer_key, :consumer_secret

  module Connection::OAuth1

    def self.included(*)
      QboApi::Connection.add_authorization_middleware :oauth1
      super
    end

    def default_attributes
      super.merge!(
        token: nil, token_secret: nil,
        consumer_key: defined?(CONSUMER_KEY) ? CONSUMER_KEY : nil,
        consumer_secret: defined?(CONSUMER_SECRET) ? CONSUMER_SECRET : nil,
      )
    end

    def add_oauth1_authorization_middleware(conn)
      gem 'simple_oauth'
      require 'simple_oauth'
      conn.request :oauth, oauth_data
    end

    def use_oauth1_middleware?
      token != nil
    end

    # https://developer.intuit.com/docs/0100_quickbooks_online/0100_essentials/0085_develop_quickbooks_apps/0004_authentication_and_authorization/oauth_management_api#/Reconnect
    def disconnect
      path = "#{APP_CONNECTION_URL}/disconnect"
      request(:get, path: path)
    end

    # https://developer.intuit.com/docs/0100_quickbooks_online/0100_essentials/0085_develop_quickbooks_apps/0004_authentication_and_authorization/oauth_management_api#/Reconnect
    def reconnect
      path = "#{APP_CONNECTION_URL}/reconnect"
      request(:get, path: path)
    end

    private

    # Use with simple_oauth OAuth1 middleware
    # @see #add_authorization_middleware
    def oauth_data
      {
        consumer_key: @consumer_key,
        consumer_secret: @consumer_secret,
        token: @token,
        token_secret: @token_secret
      }
    end

  end
end
