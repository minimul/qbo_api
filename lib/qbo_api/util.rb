class QboApi
  module Util
    def cdc_time(time)
      if time.is_a?(String)
        time
      else
        time.iso8601
      end
    end

    def uuid
      SecureRandom.uuid
    end

    def add_request_id_to(path)
      if QboApi.request_id
        add_params_to_path(path: path, params: { "requestid" => uuid })
      else
        path
      end
    end

    def add_params_to_path(path:, params:)
      uri = URI.parse(path)
      params.each do |p|
        new_query_ar = URI.decode_www_form(uri.query || '') << p.to_a
        uri.query = URI.encode_www_form(new_query_ar)
      end
      uri.to_s
    end

  end
end

