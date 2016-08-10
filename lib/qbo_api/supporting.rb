class QboApi
  module Supporting

    def cdc(entities:, changed_since:)
      path = "#{realm_id}/cdc?entities=#{entities}&changedSince=#{cdc_time(changed_since)}"
      request(:get, path: path)
    end

    def batch(payload)
      path = "#{realm_id}/batch"
      request(:post, path: path, payload: payload)
    end

  end
end
