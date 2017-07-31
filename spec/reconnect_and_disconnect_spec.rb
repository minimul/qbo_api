require 'spec_helper'

describe QboApi do
  context 'reconnect' do
    it 'out of bounds' do
      api = QboApi.new(creds.to_h)
      VCR.use_cassette("qbo_api/reconnect/out_of_bounds", record: :none) do
        response = api.reconnect
        expect(response['ErrorCode']).to eq 212
        expect(response['OAuthToken']).to be_nil
        expect(response['OAuthTokenSecret']).to be_nil
      end
    end
  end
end
