require 'spec_helper'

describe QboApi::Util do

  let(:api){ QboApi.new(creds.to_h) }


  it 'allow string to pass thru cdc_time' do
    expect(api.cdc_time("str")).to eq "str"
  end

  it 'convert Time objects to proper CDC "changed since" time stamp' do
    expect(api.cdc_time(Time.now)).to match /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/
  end

  describe '.esc' do
    it "properly handles a single quote" do
      expect(api.esc("Amy's Bird Sanctuary")).to eq "Amy\\'s Bird Sanctuary"
    end
  end

  context '.finalize_path' do
    after do
      QboApi.minor_version = false
      QboApi.request_id = false
    end

    it "add global minor version and request id plus another parameter" do
      QboApi.minor_version = 4
      QboApi.request_id = true
      path = api.entity_path(:tax_code)
      path = api.finalize_path(path, method: :post, params: { other: 12345 })
      expect(path).to match /other=12345$/
    end

    it "requestid is not implemented for non-post requests" do
      QboApi.request_id = true
      path = api.entity_path(:tax_code)
      path = api.finalize_path(path, method: :get, params: { other: 12345 })
      expect(path).to_not match /requestid=/
    end
  end

  context '.add_minor_version_to' do

    after do
      QboApi.minor_version = false
    end

    it 'is not added by default' do
      path = api.entity_path(:invoice)
      path = api.add_minor_version_to(path)
      expect(path).to_not match /minorversion/
    end

    it 'is added when configuration minor_version = 8' do
      QboApi.minor_version = 8
      path = api.entity_path(:purchase_order)
      path = api.add_minor_version_to(path)
      expect(path).to match /minorversion=8/
    end
  end

  context '.add_request_id_to' do

    after do
      QboApi.request_id = false
    end

    it 'is not added by default' do
      path = api.entity_path(:estimate)
      path = api.add_request_id_to(path)
      expect(path).to_not match /requestid/
    end

    it 'is added when configuration request_id = true' do
      QboApi.request_id = true
      path = api.entity_path(:invoice)
      path = api.add_request_id_to(path)
      expect(path).to match /requestid/
    end

    it 'is properly added when other url params are set' do
      QboApi.request_id = true
      path = api.entity_path(:sales_receipt)
      path = api.add_params_to_path(path: path, params: { operation: :delete, test: :true})
      path = api.add_request_id_to(path)
      expect(path).to match /&requestid=.*$/
    end

  end
end
