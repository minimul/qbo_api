require 'faraday'
require 'faraday_middleware'
require 'faraday/detailed_logger'

class QboApi
  module Connection

    def authorized_json_connection(url:)
      Faraday.new(url: url) do |faraday|
        faraday.headers['Content-Type'] = 'application/json;charset=UTF-8'
        faraday.headers['Accept'] = 'application/json'
        add_authorization_middleware(faraday)
        faraday.request :url_encoded
        faraday.use FaradayMiddleware::RaiseHttpException
        faraday.response :detailed_logger, QboApi.logger, LOG_TAG if QboApi.log
        faraday.adapter  Faraday.default_adapter
      end
    end

    def authorized_multipart_connection(url:)
      multipart_connection = authorized_json_connection(url: url)
      multipart_connection.headers['Content-Type'] = 'multipart/form-data'
      multipart_middleware_index = multipart_connection.builder.handlers.index(Faraday::Request::UrlEncoded) || 1
      multipart_connection.builder.insert(multipart_middleware_index, Faraday::Request::Multipart)
      multipart_connection
    end

    def request(method, path:, entity: nil, payload: nil, params: nil)
      raw_response = raw_request(method, conn: connection, path: path, params: params, payload: payload)
      response(raw_response, entity: entity)
    end

    def raw_request(method, conn:, path:, payload: nil, params: nil)
      path = finalize_path(path, method: method, params: params)
      conn.public_send(method) do |req|
        case method
        when :get, :delete
          req.url path
        when :post, :put
          req.url path
          req.body = payload.to_json
        else raise ArgumentError, "Unhandled request method '#{method.inspect}'"
        end
      end
    end

    def response(resp, entity: nil)
      data = parse_response_body(resp)
      entity ? entity_response(data, entity) : data
    rescue => e
      QboApi.logger.debug { "#{LOG_TAG} response parsing error: entity=#{entity.inspect} body=#{resp.body.inspect} exception=#{e.inspect}" }
      data
    end

    def parse_response_body(resp)
      body = resp.body
      case resp.headers['Content-Type']
      when /json/ then JSON.parse(body)
      else body
      end
    end

    # Part of the OAuth1 API
    # https://developer.intuit.com/docs/0100_quickbooks_online/0100_essentials/0085_develop_quickbooks_apps/0004_authentication_and_authorization/oauth_management_api#/Reconnect
    def disconnect
      path = "#{APP_CONNECTION_URL}/disconnect"
      request(:get, path: path)
    end

    # Part of the OAuth1 API
    # https://developer.intuit.com/docs/0100_quickbooks_online/0100_essentials/0085_develop_quickbooks_apps/0004_authentication_and_authorization/oauth_management_api#/Reconnect
    def reconnect
      path = "#{APP_CONNECTION_URL}/reconnect"
      request(:get, path: path)
    end

    private

    def entity_response(data, entity)
      entity_name = entity_name(entity)
      if data.key?('QueryResponse')
        entity_body = data['QueryResponse']
        return nil if entity_body.empty?
        entity_body.fetch(entity_name, data)
      elsif data.key?('AttachableResponse')
        entity_body = data['AttachableResponse']
        entity_body &&= entity_body.first
        entity_body.fetch(entity_name, data)
      else
        entity_body = data
        entity_body.fetch(entity_name) do
          QboApi.logger.debug { "#{LOG_TAG} entity name not in response body: entity=#{entity.inspect} entity_name=#{entity_name.inspect} body=#{data.inspect}" }
          data
        end
      end
    end

    def add_authorization_middleware(faraday)
      if @token != nil
        # Part of the OAuth1 API
        gem 'simple_oauth'
        require 'simple_oauth'
        faraday.request :oauth, oauth_data
      elsif @access_token != nil
        faraday.request :oauth2, @access_token, token_type: 'bearer'
      else
        raise QboApi::Error.new error_body: 'Must set either the token or access_token'
      end
    end

    # Part of the OAuth1 API
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

    def entity_name(entity)
      singular(entity)
    end

  end
end
