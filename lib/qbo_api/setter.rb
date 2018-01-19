class QboApi
  module Setter
    
    private

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

