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
  end
end
