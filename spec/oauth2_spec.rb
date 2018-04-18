require 'spec_helper'

describe QboApi do

  context "Use OAuth2" do
    it 'but must set an access_token' do
      api = QboApi.new realm_id: 'test'
      expect { api.get :customer, 5 }.to raise_error(QboApi::Error) {|e|
        expect(e.message).to match(/authorization_middleware/)
      }
    end

    if ENV['QBO_API_OAUTH2_ACCESS_TOKEN']
      #if the OAUTH2 access token is not nil then the creds will be the OAuth2 creds
      it 'to do a basic .get request' do
        api = QboApi.new(creds.to_h)
        use_cassette("oauth2/basic_get") do
          response = api.get(:customer, 5)
          expect(response['DisplayName']).to eq "Dukes Basketball Camp"
        end
      end
    end
  end
end
