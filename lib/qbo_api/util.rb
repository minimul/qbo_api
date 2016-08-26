class QboApi
  module Util
    def cdc_time(time)
      if time.is_a?(String)
        time
      else
        time.to_s.sub(' ', 'T').sub(' ', '').insert(-3, ':')
      end
    end

    def uuid
      SecureRandom.uuid
    end

    def add_request_id_to(path)
      if QboApi.request_id
        add_param_to_path(path: path, param: ["requestid", uuid])
      else
        path
      end
    end

    def add_param_to_path(path:, param:)
      uri = URI.parse(path)
      new_query_ar = URI.decode_www_form(uri.query || '') << param
      uri.query = URI.encode_www_form(new_query_ar)
      uri.to_s
    end

  end
end

