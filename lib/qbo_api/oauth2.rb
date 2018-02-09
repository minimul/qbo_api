require 'faraday'

class QboApi
  module OAuth2

    OAUTH2_BASE           = 'https://oauth.platform.intuit.com'
    OAUTH2_URL            =  OAUTH2_BASE + '/oauth2/v1/tokens/bearer'
    OAUTH2_EXPIRY_MARGIN   = 300 # seconds

    def oauth2_refresh!
      get_access_token
      if self.class.refresh_proc
        self.class.refresh_proc.call @refresh_token
      end
      true
    end

    def oauth2_expired?
      !@access_token || (@access_token_expiry - OAUTH2_EXPIRY_MARGIN) < Time.now
    end

    def oauth2_token
      if oauth2_expired?
        get_access_token
      end
      @access_token
    end

    private

    def get_access_token
      raw_response = oauth2_connection.post {|req|
        req.body = { grant_type: :refresh_token, refresh_token: @refresh_token }
      }
      data = JSON.parse(raw_response)
      @refresh_token = data.fetch('refresh_token')
      @access_token = data.fetch('access_token')
      @access_token_expiry = Time.now + data.fetch('access_token')
      data
    end

    def oauth2_connection
      @oauth2_connection ||= Faraday.new(url: OAUTH2_URL) do |faraday|
        faraday.basic_auth(@client_id, @client_secret)
        faraday.request :url_encoded
        faraday.headers['Accept'] = 'application/json'
        faraday.use Faraday::Response::RaiseError
        faraday.response :detailed_logger, QboApi.logger if QboApi.log
        faraday.adapter  Faraday.default_adapter
      end
    end

  end
end


module FaradayMiddleware

  class QboOAuth2 < Faraday::Middleware
    AUTH_HEADER = 'Authorization'.freeze

    def call(env)
      env[:request_headers][AUTH_HEADER] = "Bearer #{@qbo_api.oauth2_token}"
      @app.call env
    end

    def initialize(app = nil, qbo_api = nil)
      super app
      @qbo_api = qbo_api
    end

  end

end
