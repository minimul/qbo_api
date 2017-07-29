require 'spec_helper'

describe QboApi do

  context "Use OAuth2" do
    it 'but must set an access_token' do
      api = QboApi.new realm_id: 'test'
      expect { api.get :customer, 5 }.to raise_error QboApi::Error, "Must set either the token or access_token"
    end

    it 'to do a basic .get request' do
      creds = oauth2_creds
      api = QboApi.new(creds.to_h)
      VCR.use_cassette("qbo_api/oauth2/basic_get", record: :none) do
        response = api.get(:customer, 5)
        expect(response['DisplayName']).to eq "Dukes Basketball Camp"
      end
    end
  end
end
