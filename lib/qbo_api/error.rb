
#200 OK	The request succeeded.  However, the response body may contain a <Fault> element, indicating an error.
#400 Bad request	Generally, the request cannot be fulfilled due to bad syntax. In some cases, this response code is returned for a request with bad authorization data.
#401 Unauthorized	Authentication or authorization has failed.
#403 Forbidden	The resource is forbidden.
#404 Not Found	The resource is not found.
#429 Too Many Requests  API Throttling/ Rate limiting
#500 Internal Server Error	An error occurred on the server while processing the request.  Resubmit request once; if it persists, contact developer support.
#503 Service Unavailable	The service is temporarily unavailable.
# Custom error class for rescuing from all QuickBooks Online errors
class QboApi
  class Error < StandardError
    attr_reader :fault
    def initialize(errors = nil)
      if errors
        @fault = errors
        super(errors[:error_body])
      end
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

  # Raised when QuickBooks Online returns the HTTP status code 503
  class ServiceUnavailable < Error; end
end
