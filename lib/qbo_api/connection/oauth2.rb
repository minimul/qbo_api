class QboApi
  attr_accessor :access_token

  module Connection::OAuth2

    def self.included(*)
      QboApi::Connection.add_authorization_middleware :oauth2
      super
    end

    def default_attributes
      super.merge!(
        access_token: nil
      )
    end
    def add_oauth2_authorization_middleware(conn)
      conn.request :oauth2, access_token, token_type: 'bearer'
    end

    def use_oauth2_middleware?
      access_token != nil
    end
  end
end
