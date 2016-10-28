class QboApi
  module Supporting

    def cdc(entities:, changed_since:)
      path = "#{realm_id}/cdc"
      path = add_params_to_path(path: path, params: { entities: entities, changedSince: cdc_time(changed_since) })
      request(:get, path: path)
    end

    def batch(payload)
      path = "#{realm_id}/batch"
      request(:post, path: path, payload: payload)
    end

    def reports(name:, params: nil)
      path = "#{realm_id}/reports/#{name}"
      path = add_params_to_path(path: path, params: params) if params
      request(:get, path: path)
    end

  end
end
