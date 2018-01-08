class QboApi
  module Finder

    def query(query, params: nil)
      path = "#{realm_id}/query?query=#{CGI.escape(query)}"
      entity = extract_entity_from_query(query, to_sym: true)
      request(:get, entity: entity, path: path, params: params)
    end
    
    def get(entity, type, params: nil)
      if type.is_a?(Array)
        query_str = get_query_str(entity, type)
        if resp = query(query_str, params: params)
          resp.size == 1 ? resp[0] : resp
        else
          false
        end
      else
        path = "#{entity_path(entity)}/#{type}"
        request(:get, entity: entity, path: path, params: params)
      end
    end

    def to_quote_or_not(str)
      inside_parens_regex = '\(.*\)'
      if str.match(/^(#{inside_parens_regex}|true|false|CURRENT_DATE)$/)
        str
      else
        %{'#{esc(str)}'}
      end
    end

    private

    def get_query_str(entity, type)
      if type.size == 2
        operator = '='
        value = type[1]
      else
        operator = type[1]
        value = type[2]
      end
      "SELECT * FROM #{singular(entity)} WHERE #{type[0]} #{operator} #{to_quote_or_not(value)}" 
    end

  end
end
