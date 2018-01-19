class QboApi
  module All

    def all(entity, max: 1000, select: nil, inactive: false, &block)
      enumerator = create_all_enumerator(entity, max: max, select: select, inactive: inactive)

      if block_given?
        enumerator.each(&block)
      else
        enumerator
      end
    end

    private

    def create_all_enumerator(entity, max: 1000, select: nil, inactive: false)
      Enumerator.new do |enum_yielder|
        select = build_all_query(entity, select: select, inactive: inactive)
        pos = 0
        begin
          pos = pos == 0 ? pos + 1 : pos + max
          results = query("#{select} MAXRESULTS #{max} STARTPOSITION #{pos}")
          results.each do |entry|
            enum_yielder.yield(entry)
          end if results
        end while (results ? results.size == max : false)
      end
    end

  end
end
