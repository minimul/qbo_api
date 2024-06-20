require 'faraday'
require 'faraday/response/json'
require 'qbo_api/raise_http_exception'
require 'faraday/detailed_logger'
require 'faraday/multipart'

class QboApi
  module Connection
    def authorized_json_connection(url, headers: nil)
      headers ||= {}
      headers['Accept'] ||= 'application/json'
      headers['Content-Type'] ||= 'application/json;charset=UTF-8'
      build_connection(url, headers: headers) do |conn|
        conn.response :json
        add_authorization_middleware(conn)
        conn.request :url_encoded
        add_exception_middleware(conn)
        add_connection_adapter(conn)
      end
    end

    def authorized_multipart_connection(url)
      headers = {
        'Content-Type' => 'multipart/form-data',
        'Accept' => 'application/json'
      }
      build_connection(url, headers: headers) do |conn|
        conn.response :json
        add_authorization_middleware(conn)
        add_exception_middleware(conn)
        conn.request :multipart
        add_connection_adapter(conn)
      end
    end

    def build_connection(url, headers: nil)
      Faraday.new(url: url) { |conn|
        conn.response :detailed_logger, QboApi.logger, LOG_TAG if QboApi.log
        conn.headers.update(headers) if headers
        yield conn if block_given?
      }
    end

    def request(method, path:, entity: nil, payload: nil, params: nil, headers: nil)
      raw_response = raw_request(method, conn: connection, path: path, params: params, payload: payload, headers: headers)
      response(raw_response, entity: entity, headers: headers)
    end

    def raw_request(method, conn:, path:, payload: nil, params: nil, headers: nil)
      path = finalize_path(path, method: method, params: params)

      conn.public_send(method) do |req|
        req.headers = headers if headers

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

    def response(resp, entity: nil, headers: nil)
      data = resp.body
      content_type = headers['Accept'] || headers['Content-Type'] if headers

      if content_type and content_type.include?('application/pdf')
        data # return raw pdf stream
      else
        # headers are optional, must assume that application/json is default
        entity ? entity_response(data, entity) : data
      end
    rescue => e
      QboApi.logger.debug { "#{LOG_TAG} response parsing error: entity=#{entity.inspect} body=#{resp.body.inspect} exception=#{e.inspect}" }
      data
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
      conn.use QboApi::RaiseHttpException
    end

    # Faraday 2 deprecated the FaradayMiddleware gem. Middleware is
    # now part of Faraday itself, and :authorization can be used to pass
    # the Bearer token.
    def add_authorization_middleware(conn)
      conn.request :authorization, 'Bearer', access_token
    end

    def entity_name(entity)
      singular(entity)
    end
  end
end
