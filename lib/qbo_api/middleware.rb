class QboApi
  class Middleware

    def initialize
      @prependable, @appendable = [], []
    end

    def prepend(&block)
      @prependable << block
    end

    def append(&block)
      @appendable << block
    end

    def apply(conn)
      @prependable.each{|block| block.yield(conn)}
      yield conn
      @appendable.each{|block| block.yield(conn)}
    end

  end
end