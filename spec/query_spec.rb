require 'spec_helper'

describe "QboApi" do
  context ".cdc" do
    it 'should grab estimates via change data capture query' do
      api = QboApi.new(creds.to_h) 
      VCR.use_cassette("qbo_api/cdc/basic", record: :none) do
        response = api.cdc('estimate&changedSince=2011-10-10T09:00:00-07:00')
        expect(response['CDCResponse'].size).to eq 1
        ids = response['CDCResponse'][0]['QueryResponse'][0]['Estimate'].collect{ |e| e['Id'] }
        expect(ids).to eq ["48", "46", "41", "100"]
      end
    end
  end
end
