#200 OK	The request succeeded.  However, the response body may contain a <Fault> element, indicating an error.
#400 Bad request	Generally, the request cannot be fulfilled due to bad syntax. In some cases, this response code is returned for a request with bad authorization data.
#401 Unauthorized	Authentication or authorization has failed.
#403 Forbidden	The resource is forbidden.
#404 Not Found	The resource is not found.
#429 Too Many Requests  API Throttling/ Rate limiting
#500 Internal Server Error	An error occurred on the server while processing the request.  Resubmit request once; if it persists, contact developer support.
#502 Bad Gateway	The server, while acting as a gateway or proxy, received an invalid response from an inbound server it accessed while attempting to fulfill the request.
#503 Service Unavailable	The service is temporarily unavailable.
#504 Gateway Timeout
# Custom error class for rescuing from all QuickBooks Online errors
class QboApi
  class Error < StandardError
    attr_reader :fault

    def initialize(errors = {})
      @fault = errors
      super(errors[:error_body])
    end

    def fault_type
      fault.dig(:error_body, 0, :fault_type)
    end

    def error_code
      fault.dig(:error_body, 0, :error_code)
    end

    def error_message
      fault.dig(:error_body, 0, :error_message)
    end

    def error_detail
      fault.dig(:error_body, 0, :error_detail)
    end
  end

  # Raised when trying an action that is not supported
  class NotImplementedError < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 400
  class BadRequest < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 401
  class Unauthorized < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 403
  class Forbidden < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 404
  class NotFound < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 429
  class TooManyRequests < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 500
  class InternalServerError < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 502
  class BadGateway < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 503
  class ServiceUnavailable < Error; end

  # Raised when QuickBooks Online returns the HTTP status code 504
  class GatewayTimeout < Error; end
end
