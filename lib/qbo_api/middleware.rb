class QboApi
  class Middleware

    def initialize(&block)
      @prependable, @appendable = [], []
      @change_block = block
    end

    def prepend(&block)
      @change_block.call if @change_block
      @prependable << block
    end

    def append(&block)
      @change_block.call if @change_block
      @appendable << block
    end

    def apply(conn)
      @prependable.each{|block| block.yield(conn)}
      yield conn
      @appendable.each{|block| block.yield(conn)}
    end

  end
end