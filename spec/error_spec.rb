require 'spec_helper'

describe "QboApi Error handling" do
  it 'handles a 404 error' do
    api = QboApi.new(creds.to_h) 
    sql = "SELECT & FROM Customer"
    VCR.use_cassette("qbo_api/error/401", record: :none) do
      expect {
        response = api.query(sql) 
      }.to raise_error QboApi::Unauthorized
    end
  end

  it 'handles a 400 error' do
    api = QboApi.new(creds.to_h.merge(consumer_key: nil)) 
    sql = "SELECT * FROM Customer"
    VCR.use_cassette("qbo_api/error/400", record: :none) do
      expect {
        response = api.query(sql) 
      }.to raise_error QboApi::BadRequest
    end
  end

  it 'handles a 400 JSON error' do
    api = QboApi.new(creds.to_h) 
    VCR.use_cassette("qbo_api/error/400_json", record: :none) do
      expect{ response = api.create(:invoice, payload: { 'BadJson': true }) }.to raise_error QboApi::BadRequest
    end
  end

  it 'handles a 500 error' do
    api = QboApi.new(creds.to_h) 
    VCR.use_cassette("qbo_api/error/500", record: :none) do
      expect{ response = api.get(:customer, '1/5') }.to raise_error QboApi::InternalServerError
    end
  end

  it 'handles a validation error' do
    customer = { DisplayName: 'Weiskopf Consulting' } 
    api = QboApi.new(creds.to_h) 
    VCR.use_cassette("qbo_api/error/validation", record: :none) do
      begin
        response = api.create(:customer, payload: customer)
      rescue QboApi::BadRequest => e
        expect(e.fault[:error_body][0][:error_detail]).to match /Another customer/
        expect(e.message).to match /already exists/
      end
    end
  end
end
