require 'spec_helper'

describe "QboApi Error handling" do
  let(:api){ QboApi.new(creds) }

  it 'handles a 401 error' do
    # Wait until access_token expires to re-run
    use_cassette("error/401") do
      expect {
        response = api.get :customer, 1
      }.to raise_error QboApi::Unauthorized
    end
  end

  it 'handles a 400 error' do
    sql = "SELECT * FROM Custmoer" # Customer is misspelled
    use_cassette("error/400") do
      expect {
        response = api.query(sql)
      }.to raise_error QboApi::BadRequest
    end
  end

  it 'handles a 400 JSON error' do
    use_cassette("error/400_json") do
      expect {
        response = api.create(:invoice, payload: { 'BadJson': true })
      }.to raise_error QboApi::BadRequest
    end
  end

  it 'handles a validation error' do
    customer = { DisplayName: 'Weiskopf Consulting' }
    use_cassette("error/validation") do
      begin
        response = api.create(:customer, payload: customer)
      rescue QboApi::BadRequest => e
        expect(e.fault[:error_body][0][:error_detail]).to match /already exists/
        expect(e.message).to match /already exists/
      end
    end
  end

  it "handles XML error in which the first error does not have a 'Detail' error" do
    xml = fixture('no_detail.xml')
    f = FaradayMiddleware::RaiseHttpException.new(double('app'))
    err = f.send(:error_body, xml)
    expect(err[0][:error_detail]).to eq ""
    expect(err[1][:error_detail]).to match /does have detail/
  end
end
