class QboApi
  module Builder
    
    private 

    def build_update(resp)
      { Id: resp['Id'], SyncToken: resp['SyncToken'] }
    end

    def build_deactivate(entity, resp)
      payload = build_update(resp).merge('sparse': true, 'Active': false)

      case singular(entity)
      when 'Account'
        payload['Name'] = resp['Name']
      end
      payload
    end

  end
end
