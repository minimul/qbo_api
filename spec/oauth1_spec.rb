require 'spec_helper'

describe QboApi do

  let(:api){ QboApi.new(creds.to_h) }

  context 'reconnect' do
    it 'out of bounds' do
      use_cassette("oauth1/reconnect/out_of_bounds") do
        response = api.reconnect
        expect(response['ErrorCode']).to eq 212
        expect(response['OAuthToken']).to be_nil
        expect(response['OAuthTokenSecret']).to be_nil
      end
    end
  end
end
