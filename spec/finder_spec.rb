require 'spec_helper'

describe QboApi::Finder do

  let(:api) { QboApi.new(creds.to_h) }

  it '.to_quote_or_not' do
    ['true', 'false', 'CURRENT_DATE', '( true, false)'].each do |str|
      expect(api.to_quote_or_not(str)).to_not match /^\'.*\'$/
    end
    ['true & false', 'false, true', 'CURRENT_TIME', 'trueliy)'].each do |str|
      expect(api.to_quote_or_not(str)).to match /^\'.*\'$/
    end
  end

  it 'get an entity by its id' do
    use_cassette("qbo_api/get/id") do
      response = api.get(:customer, 5)
      expect(response['DisplayName']).to eq "Dukes Basketball Camp"
    end
  end

  it 'get an entity by display name with a irregular character' do
    use_cassette("qbo_api/get/display_name") do
      name = "Amy's Bird Sanctuary"
      response = api.get(:customer,  [ 'DisplayName', name ])
      expect(response['DisplayName']).to eq name
    end
  end

  it 'get vendors whether active or inactive' do
    use_cassette("qbo_api/get/inactive_vendors") do
      response = api.get(:vendor,  [ 'Active', 'IN', '(true, false)' ])
      expect(response.size).to be > 1
    end
  end

  it 'search with ampersand with query method' do
    use_cassette("qbo_api/misc/ampersand") do
      name = "Robertson & Associates"
      response = api.query(%{SELECT * FROM Vendor WHERE DisplayName = '#{name}'})
      expect(response.first['DisplayName']).to eq name
    end
  end

end
