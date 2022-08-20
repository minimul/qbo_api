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

    def deliver(entity, entity_id:, email_address: nil)
      valid_entities = %i(invoice estimate purchaseorder creditmemo salesreceipt refundreceipt)
      unless valid_entities.include?(entity.to_sym)
        raise ArgumentError, "Invalid entity type '#{entity}'. Must be one of: #{valid_entities.join(', ')}"
      end

      path = "#{realm_id}/#{entity}/#{entity_id}/send"
      unless email_address.nil?
        params = { minorversion: 63, sendTo: email_address }
        path = add_params_to_path(path: path, params: params)
      end
      headers = { 'Content-Type' => 'application/octet-stream' }
      request(:post, path: path, headers: headers)
    end
  end
end
