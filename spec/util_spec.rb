require 'spec_helper'

describe QboApi::Util do

  it 'allow string to pass thru cdc_time' do
    api = QboApi.new(creds.to_h) 
    expect(api.cdc_time("str")).to eq "str"
  end

  it 'convert Time objects to proper CDC "changed since" time stamp' do
    api = QboApi.new(creds.to_h)
    expect(api.cdc_time(Time.now)).to match /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-\d{2}:\d{2}$/
  end

  describe '.esc' do
    it "properly handles a single quote" do
      api = QboApi.new(creds.to_h)
      expect(api.esc("Amy's Bird Sanctuary")).to eq "Amy\\'s Bird Sanctuary"
    end
  end

  context '.add_request_id_to' do

    after do
      QboApi.request_id = false
    end

    it 'is not added by default' do
      api = QboApi.new(creds.to_h)
      path = api.entity_path(:estimate)
      path = api.add_request_id_to(path)
      expect(path).to_not match /requestid/
    end

    it 'is added when configuration request_id = true' do
      QboApi.request_id = true
      api = QboApi.new(creds.to_h)
      path = api.entity_path(:invoice)
      path = api.add_request_id_to(path)
      expect(path).to match /requestid/
    end

    it 'is properly added when other url params are set' do
      QboApi.request_id = true
      api = QboApi.new(creds.to_h)
      path = api.entity_path(:sales_receipt)
      path = api.add_params_to_path(path: path, params: { operation: :delete, test: :true})
      path = api.add_request_id_to(path)
      expect(path).to match /&requestid=.*$/
    end

  end
end
