require 'faraday'
require 'faraday_middleware'
require 'faraday/detailed_logger'

class QboApi
  module Connection
    AUTHORIZATION_MIDDLEWARES = []

    def Connection.add_authorization_middleware(strategy_name)
      Connection::AUTHORIZATION_MIDDLEWARES << strategy_name
    end

    def authorized_json_connection(url, headers: nil)
      headers ||= {}
      headers['Accept'] ||= 'application/json' # required "we'll only accept JSON". Can be changed to any `+json` media type.
      headers['Content-Type'] ||= 'application/json;charset=UTF-8' # required when request has a body, else harmless
      build_connection(url, headers: headers) do |conn|
        add_authorization_middleware(conn)
        add_exception_middleware(conn)
        conn.request :url_encoded
        add_connection_adapter(conn)
      end
    end

    def authorized_multipart_connection(url)
      headers = {
        'Content-Type' => 'multipart/form-data',
        'Accept' => 'application/json'
      }
      build_connection(url, headers: headers) do |conn|
        add_authorization_middleware(conn)
        add_exception_middleware(conn)
        conn.request :multipart
        add_connection_adapter(conn)
      end
    end

    # @example
    #   connection = build_connection('https://oauth.platform.intuit.com', headers: { 'Accept' => 'application/json' }) do |conn|
    #     conn.basic_auth(client_id, client_secret)
    #     conn.request :url_encoded # application/x-www-form-urlencoded
    #     conn.use FaradayMiddleware::ParseJson, parser_options: { symbolize_names: true }
    #     conn.use Faraday::Response::RaiseError
    #   end
    #   raw_response = connection.post {|req|
    #     req.body = { grant_type: :refresh_token, refresh_token: current_refresh_token }
    #     req.url '/oauth2/v1/tokens/bearer'
    #   }
    def build_connection(url, headers: nil)
      Faraday.new(url: url) { |conn|
        conn.response :detailed_logger, QboApi.logger, LOG_TAG if QboApi.log
        conn.headers.update(headers) if headers
        yield conn if block_given?
      }
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

    def add_connection_adapter(conn)
      conn.adapter Faraday.default_adapter
    end

    def add_exception_middleware(conn)
      conn.use FaradayMiddleware::RaiseHttpException
    end

    def add_authorization_middleware(conn)
      Connection::AUTHORIZATION_MIDDLEWARES.find(proc do
        raise QboApi::Error.new error_body: 'Add a configured authorization_middleware'
      end) do |strategy_name|
        next unless public_send("use_#{strategy_name}_middleware?")
        public_send("add_#{strategy_name}_authorization_middleware", conn)
        true
      end
    end

    def entity_name(entity)
      singular(entity)
    end

    require_relative 'connection/oauth1'
    include OAuth1
    require_relative 'connection/oauth2'
    include OAuth2
  end
end
