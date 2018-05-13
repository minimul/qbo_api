require 'spec_helper'

describe QboApi::ApiMethods do

  let(:api) { QboApi.new(creds.to_h) }

  QboApi.send(:public, :to_quote_or_not)

  describe "get, filtered get, and query" do

    it '.to_quote_or_not' do
      ['true', 'false', 'CURRENT_DATE', '( true, false)'].each do |str|
        expect(api.to_quote_or_not(str)).to_not match(/^\'.*\'$/)
      end
      ['true & false', 'false, true', 'CURRENT_TIME', 'trueliy)'].each do |str|
        expect(api.to_quote_or_not(str)).to match(/^\'.*\'$/)
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

  describe ".create" do

    after do
      QboApi.request_id = false
    end

    it 'an invoice' do
      invoice = {
        "Line": [
          {
            "Amount": 100.00,
            "DetailType": "SalesItemLineDetail",
            "SalesItemLineDetail": {
              "ItemRef": {
                "value": "1",
                "name": "Services"
              }
            }
          }
        ],
        "CustomerRef": {
          "value": "1"
        }
      }
      use_cassette("qbo_api/create/invoice") do
        response = api.create(:invoice, payload: invoice)
        #p response['Id']
        expect(response['Id']).to_not be_nil
      end
    end

    it 'a customer using a request id' do
      customer =
        if creds_type == :oauth2_creds
          { DisplayName: 'Doe2, Jane' } # avoids duplicate name error
        else
          { DisplayName: 'Doe, Jane' }
        end
      QboApi.request_id = true
      use_cassette("qbo_api/create/customer") do
        response = api.create(:customer, payload: customer)
        expect(response['Id']).to_not be_nil
      end
    end
  end

  describe '.update' do

    it 'a customer using a minor version configuration' do
      customer = {
        DisplayName: 'Jack Doe',
        PrimaryPhone: {
          FreeFormNumber: "(415) 444-1234"
        }
      }
      QboApi.minor_version = 8
      use_cassette("qbo_api/update/customer") do
        # Use the id of the created customer above
        response = api.update(:customer, id: 60, payload: customer)
        expect(response.fetch('PrimaryPhone').fetch('FreeFormNumber')).to eq "(415) 444-1234"
      end
      QboApi.minor_version = false
    end

    it 'a sales receipt with minor version and request id set for the individual request' do
      sales_receipt = {
        Line: [
          {
            "Description": "Custom Design",
            "Amount": 337.5,
            "DetailType": "SalesItemLineDetail",
            "SalesItemLineDetail": {
              "ItemRef": {
                "value": "4",
                "name": "Design"
              },
              "UnitPrice": 75,
              "Qty": 4.5,
              "TaxCodeRef": {
                "value": "NON"
              }
            }
          }
        ]
      }
      use_cassette("qbo_api/update/sales_receipt") do
        # SalesReceipt = 17 is part of default sandbox
        response = api.update(:sales_receipt, id: 17, payload: sales_receipt, params: { minorversion: 4, requestid: api.uuid })
        expect(response['SyncToken'].to_i).to be > 0
      end
    end
  end #= end '.update

  describe '.delete' do
    let(:invoice_id) do
      # Use the id of the created invoice above
      if creds_type == :oauth2_creds
        # spec/vcr/oauth2_creds/qbo_api/create/invoice.yml
        146
      else
        145
      end
    end
    it 'an invoice' do
      use_cassette("qbo_api/delete/invoice") do
        response = api.delete(:invoice, id: invoice_id)
        expect(response['status']).to eq "Deleted"
      end
    end

    it 'only a transaction entity' do
      expect { api.delete(:customer, id: invoice_id) }.to raise_error QboApi::NotImplementedError, /^Delete is only for/
    end
  end

  describe '.deactivate' do
    it 'an employee' do
      use_cassette("qbo_api/deactivate/employee") do
        response = api.deactivate(:employee, id: 55)
        expect(response['Active']).to eq false
      end
    end

    it 'an account' do
      use_cassette("qbo_api/deactivate/account") do
        response = api.deactivate(:account, id: 5)
        expect(response['Active']).to eq false
      end
    end

    it 'only a name list entity' do
      expect { api.deactivate(:refund_receipt, id: 145) }.to raise_error QboApi::NotImplementedError, /^Deactivate is only for/
    end
  end

  describe "QboApi Import All entities" do
    context "backwards compatability (with block)" do
      it 'retrieves all customers' do
        counter = []
        use_cassette("qbo_api/all/customers") do
          result = api.query("SELECT COUNT(*) FROM Customer")
          count = result['QueryResponse']['totalCount']
          _response = api.all(:customers) do |c|
            counter << "#{c['Id']} #{c['DisplayName']}"
          end
          expect(counter.size).to eq count
        end
      end
    end

    it 'retrieves all customers' do
      use_cassette("qbo_api/all/customers") do
        result = api.query("SELECT COUNT(*) FROM Customer")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customers)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all employees including inactive ones' do
      use_cassette("qbo_api/all/employees_including_active") do
        result = api.query("SELECT COUNT(*) FROM Employee WHERE Active IN (true, false) ")
        count = result['QueryResponse']['totalCount']
        response = api.all(:employees, inactive: true)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all vendors by groups of 5' do
      use_cassette("qbo_api/all/vendors_by_5") do
        result = api.query("SELECT COUNT(*) FROM Vendor")
        count = result['QueryResponse']['totalCount']
        response = api.all(:vendor, max: 5)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all customers, including inactive ones, by groups of 2 by alternate select query' do
      where = "WHERE Id IN ('5', '6', '7', '8', '9', '10')"
      use_cassette("qbo_api/all/alt_select") do
        result = api.query("SELECT count(*) FROM Customer #{where}")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customer, max: 2, select: "SELECT * FROM Customer #{where}", inactive: true)
        expect(response.count).to eq count
      end
    end

    it 'retrieves sales receipts' do
      use_cassette("qbo_api/all/sales_receipts") do
        first_id = api.all(:sales_receipts).first['Id']
        expect(first_id).to eq "17"
      end
    end
  end
end
