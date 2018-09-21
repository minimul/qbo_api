class QboApi
  module ApiMethods

    def all(entity, max: 1000, select: nil, inactive: false, params: nil, &block)
      enumerator = create_all_enumerator(entity, max: max, select: select, inactive: inactive, params: params)

      if block_given?
        enumerator.each(&block)
      else
        enumerator
      end
    end

    def query(query, params: nil)
      path = "#{realm_id}/query?query=#{CGI.escape(query)}"
      entity = extract_entity_from_query(query, to_sym: true)
      request(:get, entity: entity, path: path, params: params)
    end

    # @example
    #   get(:customer, 5)
    # @see #get_by_query_filter
    def get(entity, id_or_query_filter_args, params: nil)
      if id_or_query_filter_args.is_a?(Array)
        get_by_query_filter(entity, id_or_query_filter_args, params: params)
      else
        path = "#{entity_path(entity)}/#{id_or_query_filter_args}"
        request(:get, entity: entity, path: path, params: params)
      end
    end

    # @example
    #   get_by_query_filter(:customer, ["DisplayName", "Dukes Basketball Camp"])
    #   get_by_query_filter(:customer, ["DisplayName", "LIKE", "Dukes%"])
    #   get_by_query_filter(:vendor, ["DisplayName", "IN", "(true, false)"])
    #   get_by_query_filter(:customer, ["DisplayName", "Amy's Bird Sanctuary"])
    def get_by_query_filter(entity, query_filter_args, params: nil)
      query_str = get_query_str(entity, query_filter_args)
      if resp = query(query_str, params: params)
        resp.size == 1 ? resp[0] : resp
      else
        false
      end
    end

    def create(entity, payload:, params: nil)
      request(:post, entity: entity, path: entity_path(entity), payload: payload, params: params)
    end

    def update(entity, id:, payload:, params: nil)
      payload.merge!(set_update(entity, id))
      request(:post, entity: entity, path: entity_path(entity), payload: payload, params: params)
    end

    def delete(entity, id:)
      err_msg = "Delete is only for transaction entities. Use .deactivate instead"
      raise QboApi::NotImplementedError.new, err_msg unless is_transaction_entity?(entity)
      path = add_params_to_path(path: entity_path(entity), params: { operation: :delete })
      payload = set_update(entity, id)
      request(:post, entity: entity, path: path, payload: payload)
    end

    def deactivate(entity, id:)
      err_msg = "Deactivate is only for name list entities. Use .delete instead"
      raise QboApi::NotImplementedError.new, err_msg unless is_name_list_entity?(entity)
      payload = set_deactivate(entity, id)
      request(:post, entity: entity, path: entity_path(entity), payload: payload)
    end

    private

    def get_query_str(entity, query_filter_args)
      filterable_field = query_filter_args[0]
      operator = query_filter_args.size == 2 ? '=' : query_filter_args[1]
      value = query_filter_args.size == 2 ? query_filter_args[1] : query_filter_args[2]
      "SELECT * FROM #{singular(entity)} WHERE #{filterable_field} #{operator} #{to_quote_or_not(value)}"
    end

    def to_quote_or_not(str)
      inside_parens_regex = '\(.*\)'
      if str.match(/^(#{inside_parens_regex}|true|false|CURRENT_DATE)$/)
        str
      else
        %{'#{esc(str)}'}
      end
    end

    def create_all_enumerator(entity, max: 1000, select: nil, inactive: false, params: nil)
      Enumerator.new do |enum_yielder|
        select = build_all_query(entity, select: select, inactive: inactive)
        pos = 0
        begin
          pos = pos == 0 ? pos + 1 : pos + max
          results = query(offset_query_string(select, limit: max, offset: pos), params: params)
          results.each do |entry|
            enum_yielder.yield(entry)
          end if results
        end while (results ? results.size == max : false)
      end
    end

    # NOTE(BF): QuickBooks offsets start at 1, but our convention is to index at 0.
    # That is, to get an offset of index 0, pass in 1, and so forth.
    def offset_query_string(query_string, limit:, offset:)
      "#{query_string} MAXRESULTS #{limit} STARTPOSITION #{offset}"
    end

    def join_or_start_where_clause!(select:)
      if select.match(/where/i)
        str = ' AND '
      else
        str = ' WHERE '
      end
      str
    end

    def build_all_query(entity, select: nil, inactive: false)
      select ||= "SELECT * FROM #{singular(entity)}"
      select += join_or_start_where_clause!(select: select) + 'Active IN ( true, false )' if inactive
      select
    end

    def build_update(resp)
      { Id: resp['Id'], SyncToken: resp['SyncToken'] }
    end

    def build_deactivate(entity, resp)
      payload = build_update(resp).merge('sparse': true, 'Active': false)

      case singular(entity)
      when 'Account', 'Class'
        payload['Name'] = resp['Name']
      end
      payload
    end

    def set_update(entity, id)
      resp = get(entity, id)
      build_update(resp)
    end

    def set_deactivate(entity, id)
      resp = get(entity, id)
      build_deactivate(entity, resp)
    end

  end
end
