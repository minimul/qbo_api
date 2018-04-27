class QboApi
  class Middleware

    def initialize(on_change: nil)
      @prependable, @appendable = [], []
      @change_proc = on_change
    end

    def prepend(&block)
      @change_proc.call if @change_proc
      @prependable << block
    end

    def append(&block)
      @change_proc.call if @change_proc
      @appendable << block
    end

    def apply(conn)
      @prependable.each{|block| block.yield(conn)}
      yield conn
      @appendable.each{|block| block.yield(conn)}
    end

  end
end