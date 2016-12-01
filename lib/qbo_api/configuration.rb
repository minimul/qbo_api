class QboApi
  module Configuration

    def logger
      @logger ||= ::Logger.new($stdout)
    end

    def logger=(logger)
      @logger = logger
    end

    def log
      @log ||= false
    end

    def log=(value)
      @log = value
    end

    def production
      @production ||= false
    end

    def production=(value)
      @production = value
    end

    def request_id
      @request_id ||= false
    end

    def request_id=(value)
      @request_id = value
    end

    def minor_version
      @minor_version ||= false
    end

    def minor_version=(value)
      @minor_version = value
    end
  end
end
