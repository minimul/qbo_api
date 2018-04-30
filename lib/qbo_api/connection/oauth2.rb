class QboApi
  attr_accessor :client_id, :client_secret, :refresh_proc

  OAUTH2_BASE           = 'https://oauth.platform.intuit.com'
  OAUTH2_URL            =  OAUTH2_BASE + '/oauth2/v1/tokens/bearer'

  def access_token
    @access_token || (refresh_access_token! if refresh_token)
  end

  def access_token=(token)
    reset_connections
    @access_token = token
  end

  def refresh_token
    @refresh_token
  end

  def refresh_token=(token)
    reset_connections if refresh_token
    refresh_proc.call(token) if refresh_proc and refresh_token
    @refresh_token = token
  end

  def refresh_access_token!
    resp = oauth2_connection.post do |req|
      req.body = {
          grant_type: :refresh_token,
          refresh_token: refresh_token
      }
    end
    data = parse_response_body(resp)
    self.refresh_token = data.fetch('refresh_token')
    self.access_token = data.fetch('access_token')
  end

  def oauth2_connection
    headers = {'Accept' => 'application/json'}
    @oauth2_connection ||= build_connection(OAUTH2_URL, headers: headers) do |conn|
      conn.basic_auth(client_id, client_secret)
      conn.request :url_encoded
      conn.use Faraday::Response::RaiseError
      add_connection_adapter(conn)
    end
  end

  module Connection::OAuth2

    def self.included(*)
      QboApi::Connection.add_authorization_middleware :oauth2
      super
    end

    def default_attributes
      super.merge!(
        access_token:   nil,
        refresh_token:  nil,
        client_id:      defined?(CLIENT_ID) ? CLIENT_ID : nil,
        client_secret:  defined?(CLIENT_SECRET) ? CLIENT_SECRET : nil,
        refresh_proc:   nil
      )
    end

    def add_oauth2_authorization_middleware(conn)
      conn.request :oauth2, access_token, token_type: 'bearer'
      conn.use FaradayMiddleware::OAuth2Refresh, self if refresh_token
    end

    def use_oauth2_middleware?
      refresh_token || access_token
    end
  end
end


# @private
module FaradayMiddleware
  # @private
  class OAuth2Refresh < Faraday::Middleware
    AUTH_HEADER = 'Authorization'.freeze

    def call(env)
      begin
        @app.call(env).tap do |resp|
          raise QboApi::Unauthorized if resp.status == 401
        end
      rescue QboApi::Unauthorized => _error
        env[:request_headers][AUTH_HEADER] = "Bearer #{@qbo_api.refresh_access_token!}"
        retry
      end
    end

    def initialize(app, qbo_api)
      @qbo_api = qbo_api
      super app
    end

  end
end
