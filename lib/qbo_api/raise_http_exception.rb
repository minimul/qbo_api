require 'faraday'
require 'nokogiri'

# @private
module FaradayMiddleware
  # @private
  class RaiseHttpException < Faraday::Middleware
    def call(env)
      @app.call(env).on_complete do |response|
        case response.status
        when 200
        when 400
          raise QboApi::BadRequest.new(error_message(response))
        when 401
          raise QboApi::Unauthorized.new(error_message(response))
        when 403
          raise QboApi::Forbidden.new(error_message(response))
        when 404
          raise QboApi::NotFound.new(error_message(response))
        when 429
          raise QboApi::TooManyRequests.new(error_message(response))
        when 500
          raise QboApi::InternalServerError.new(error_message(response))
        when 503
          raise QboApi::ServiceUnavailable.new(error_message(response))
        end
      end
    end

    def initialize(app)
      super app
    end

    private

    def error_message(response)
      {
        method: response.method,
        url: response.url,
        status: response.status,
        error_body: error_body(response.body)
      }
    end

    def error_body(body)
      if not body.nil? and not body.empty? and body.kind_of?(String)
        body =~ /IntuitResponse/ ? parse_xml(body) : parse_json(body)
      else
        nil
      end
    end

    def parse_json(body)
      res = ::JSON.parse(body)
      fault = res['Fault'] || res['fault']
      errors = fault['Error'] || fault['error']
      errors.collect do |error|
        {
          fault_type: fault['type'],
          error_code: error['code'],
          error_message: error['Message'] || error['message'],
          error_detail: error['Detail'] || error['detail']
        }
      end
    end

    def parse_xml(body)
      res = ::Nokogiri::XML(body)
      r = res.css('Error')
      r.collect do |e|
        {
          fault_type: res.at('Fault')['type'],
          error_code: res.at('Error')['code'],
          error_message: e.at('Message').content,
          error_detail: (detail = e.at('Detail')) ? detail.content : ''
        }
      end
    end

  end
end
