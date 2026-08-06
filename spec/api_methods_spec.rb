require 'spec_helper'

describe QboApi::ApiMethods do
  let(:api) { QboApi.new(creds) }

  QboApi.send(:public, :to_quote_or_not)

  # Proves the caller's SyncToken - not a server-fetched one - is what goes on the
  # wire: the POST body carries exactly the supplied token, and no GET was made to
  # fetch a fresh one first. (VCR matches on method+URI only, so webmock still
  # records the real outgoing body for us to inspect.)
  def expect_supplied_sync_token_sent(entity_path:, sync_token:)
    expect(a_request(:get, %r{#{entity_path}})).not_to have_been_made
    expect(
      a_request(:post, %r{#{entity_path}}).with { |req| JSON.parse(req.body)['SyncToken'] == sync_token }
    ).to have_been_made, "Expected request to have sync token '#{sync_token}' in the body, but it did not."
  end

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
      use_cassette("get/id") do
        response = api.get(:customer, 5)
        expect(response['DisplayName']).to eq "Dukes Basketball Camp"
      end
    end

    it 'get an entity by display name with a irregular character' do
      use_cassette("get/display_name") do
        name = "Amy's Bird Sanctuary"
        response = api.get(:customer,  [ 'DisplayName', name ])
        expect(response['DisplayName']).to eq name
      end
    end

    it 'get vendors whether active or inactive' do
      use_cassette("get/inactive_vendors") do
        response = api.get(:vendor,  [ 'Active', 'IN', '(true, false)' ])
        expect(response.size).to be > 1
      end
    end

    it 'search with ampersand with query method' do
      use_cassette("misc/ampersand") do
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
      use_cassette("create/invoice") do
        response = api.create(:invoice, payload: invoice)
        # p response['Id']
        expect(response['Id']).to_not be_nil
      end
    end

    it 'a customer using a request id', skip: with_cannot_match_cassette_error do
      customer = { DisplayName: 'Doe5, Jane' } # on a re-run alter the name to avoid duplicate error
      QboApi.request_id = true
      use_cassette("create/customer") do
        response = api.create(:customer, payload: customer)
        # p response['Id']
        expect(response['Id']).to_not be_nil
      end
    end
  end

  describe '.update' do

    it 'a customer using a minor version configuration' do
      phone_num = "(415) 444-1234"
      customer = {
        DisplayName: 'Jack Moe',
        PrimaryPhone: {
          FreeFormNumber: phone_num
        }
      }
      QboApi.minor_version = 8
      use_cassette("update/customer") do
        # Use the id of the created customer above - see describe '.create' section
        response = api.update(:customer, id: 68, payload: customer)
        expect(response.fetch('PrimaryPhone').fetch('FreeFormNumber')).to eq phone_num
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
      use_cassette("update/sales_receipt") do
        # SalesReceipt = 17 is part of default sandbox
        response = api.update(:sales_receipt, id: 17, payload: sales_receipt, params: { minorversion: 4, requestid: api.uuid })
        expect(response['SyncToken'].to_i).to be > 0
      end
    end

    it 'sends the supplied sync_token for a customer instead of fetching the current one' do
      customer = {
        DisplayName: 'Jack Moe',
        PrimaryPhone: {
          FreeFormNumber: "(415) 444-1234"
        }
      }
      use_cassette("update/customer_with_sync_token") do
        api.update(:customer, id: 483, payload: customer, sync_token: '99')
        expect_supplied_sync_token_sent(entity_path: '/customer', sync_token: '99')
      end
    end
  end #= end '.update

  describe '.delete' do
    it 'an invoice' do
      use_cassette("delete/invoice") do
        response = api.delete(:invoice, id: 266)
        expect(response['status']).to eq "Deleted"
      end
    end

    it 'only a transaction entity' do
      expect { api.delete(:customer, id: 266) }.to raise_error QboApi::NotImplementedError, /^Delete is only for/
    end

    it 'sends the supplied sync_token for an invoice instead of fetching the current one' do
      use_cassette("delete/invoice_with_sync_token") do
        api.delete(:invoice, id: 213, sync_token: '99')
        expect_supplied_sync_token_sent(entity_path: '/invoice', sync_token: '99')
      end
    end
  end

  describe '.void' do
    it 'an invoice', skip: with_cannot_match_cassette_error do
      use_cassette("void/invoice") do
        response = api.void(:invoice, id: 264)
        expect(response['PrivateNote']).to eq "Voided"
      end
    end

    it 'only a voidable entity' do
      expect { api.void(:vendor, id: 34) }.to raise_error QboApi::NotImplementedError, /^Void is only for/
    end

    it 'sends the supplied sync_token for an invoice instead of fetching the current one' do
      use_cassette("void/invoice_with_sync_token") do
        api.void(:invoice, id: 214, sync_token: '99')
        expect_supplied_sync_token_sent(entity_path: '/invoice', sync_token: '99')
      end
    end
  end

  describe '.deactivate' do
    it 'an employee' do
      use_cassette("deactivate/employee") do
        response = api.deactivate(:employee, id: 55)
        expect(response['Active']).to eq false
      end
    end

    it 'an account' do
      use_cassette("deactivate/account") do
        response = api.deactivate(:account, id: 5)
        expect(response['Active']).to eq false
      end
    end

    it 'sends the supplied sync_token for an employee instead of fetching the current one' do
      use_cassette("deactivate/employee_with_sync_token") do
        api.deactivate(:employee, id: 400000001, sync_token: '99')
        expect_supplied_sync_token_sent(entity_path: '/employee', sync_token: '99')
      end
    end

    it 'an account with a supplied sync_token still fetches (for Name) but sends the supplied SyncToken' do
      use_cassette("deactivate/account") do
        # Account/Class still GET (to read the current Name), so unlike the other entities a fetch
        # does happen here. The cassette's fetched SyncToken is "1"; we deliberately supply a
        # different value so the assertion proves the caller's value - not the freshly fetched one -
        # is what's sent in the payload.
        response = api.deactivate(:account, id: 5, sync_token: '99')
        expect(response['Active']).to eq false
        expect(
          a_request(:post, %r{/account\z}).with { |req| JSON.parse(req.body)['SyncToken'] == '99' }
        ).to have_been_made, "Expected request to have sync token '99' in the body, but it did not."
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
        use_cassette("all/customers") do
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
      use_cassette("all/customers") do
        result = api.query("SELECT COUNT(*) FROM Customer")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customers)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all employees including inactive ones' do
      use_cassette("all/employees_including_active") do
        result = api.query("SELECT COUNT(*) FROM Employee WHERE Active IN (true, false) ")
        count = result['QueryResponse']['totalCount']
        response = api.all(:employees, inactive: true)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all vendors by groups of 5' do
      use_cassette("all/vendors_by_5") do
        result = api.query("SELECT COUNT(*) FROM Vendor")
        count = result['QueryResponse']['totalCount']
        response = api.all(:vendor, max: 5)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all customers, including inactive ones, by groups of 2 by alternate select query' do
      where = "WHERE Id IN ('5', '6', '7', '8', '9', '10')"
      use_cassette("all/alt_select") do
        result = api.query("SELECT count(*) FROM Customer #{where}")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customer, max: 2, select: "SELECT * FROM Customer #{where}", inactive: true)
        expect(response.count).to eq count
      end
    end

    it 'retrieves sales receipts' do
      use_cassette("all/sales_receipts") do
        first_id = api.all(:sales_receipts).first['Id']
        expect(first_id).to eq "17"
      end
    end
  end

  describe 'get pdf' do
    let(:entity) { :invoice }
    let(:id) { '130' }

    it 'requests the pdf of an invoice' do
      use_cassette('get_pdf/invoice') do
        result = api.get_pdf(entity, id)
        pdf_starts_correctly = result&.match(/^%PDF-\d+(\.\d+)?/)
        expect(pdf_starts_correctly).to be_truthy
      end
    end
  end
end
