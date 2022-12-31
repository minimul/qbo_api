require 'faraday'
require 'faraday/response'
require 'nokogiri'
# @private
class QboApi
  # @private
  class RaiseHttpException < Faraday::Response::RaiseError
    def on_complete(env)
      case env[:status]
      when 400
        raise QboApi::BadRequest.new(error_message(env))
      when 401
        raise QboApi::Unauthorized.new(error_message(env))
      when 403
        raise QboApi::Forbidden.new(error_message(env))
      when 404
        raise QboApi::NotFound.new(error_message(env))
      when 407
        # mimic the behavior that we get with proxy requests with HTTPS
        msg = %(407 "Proxy Authentication Required")
        raise Faraday::ProxyAuthError.new(msg, response_values(env))
      when 409
        raise Faraday::ConflictError, response_values(env)
      when 422
        raise Faraday::UnprocessableEntityError, response_values(env)
      when 429
        raise QboApi::TooManyRequests.new(error_message(env))
      when 500
        raise QboApi::InternalServerError.new(error_message(env))
      when 502
        raise QboApi::BadGateway.new({ error_body: env.reason_phrase })
      when 503
        raise QboApi::ServiceUnavailable.new(error_message(env))
      when 504
        raise QboApi::GatewayTimeout.new(error_message(env))
      when ClientErrorStatuses
        raise Faraday::ClientError, response_values(env)
      when ServerErrorStatuses
        raise Faraday::ServerError, response_values(env)
      when nil
        raise Faraday::NilStatusError, response_values(env)
      end
    end

    def initialize(app)
      super app
    end

    private

    def error_message(env)
      {
        method: env.method,
        url: env.url,
        status: env.status,
        error_body: error_body(env.body),
        intuit_tid: env[:response_headers]['intuit_tid']
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
