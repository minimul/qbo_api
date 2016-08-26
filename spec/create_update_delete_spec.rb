require 'spec_helper'

describe "QboApi Create Update Delete" do
  context ".create" do

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
      api = QboApi.new(creds.to_h) 
      VCR.use_cassette("qbo_api/create/invoice", record: :none) do
        response = api.create(:invoice, payload: invoice)
        #p response['Id']
        expect(response['Id']).to_not be_nil
      end
    end

    it 'a customer using a request id' do
      customer = { DisplayName: 'Doe, Jane' } 
      QboApi.request_id = true
      api = QboApi.new(creds.to_h) 
      VCR.use_cassette("qbo_api/create/customer", record: :none) do
        response = api.create(:customer, payload: customer)
        expect(response['Id']).to_not be_nil
      end
    end
  end

  context '.update' do
    it 'a customer' do
      customer = { 
        DisplayName: 'Jack Doe',
        PrimaryPhone: {
          FreeFormNumber: "(415) 444-1234"
        }
      }
      api = QboApi.new(creds.to_h) 
      VCR.use_cassette("qbo_api/update/customer", record: :none) do
        # Use the id of the created customer above
        response = api.update(:customer, id: 60, payload: customer)
        expect(response.fetch('PrimaryPhone').fetch('FreeFormNumber')).to eq "(415) 444-1234"
      end
    end

    it 'a sales receipt' do
      #QboApi.log = true
      api = QboApi.new(creds.to_h) 
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
      VCR.use_cassette("qbo_api/update/sales_receipt", record: :none) do
        # SalesReceipt = 17 is part of default sandbox
        response = api.update(:sales_receipt, id: 17, payload: sales_receipt)
        expect(response['SyncToken']).to eq "1"
      end
    end
  end #= end '.update

  context '.delete' do
    it 'an invoice' do
      api = QboApi.new(creds.to_h) 
      VCR.use_cassette("qbo_api/delete/invoice", record: :none) do
        # Use the id of the created invoice above
        response = api.delete(:invoice, id: 145)
        expect(response['status']).to eq "Deleted"
      end
    end

    it 'only of a transaction entity' do
      api = QboApi.new(creds.to_h) 
      expect { response = api.delete(:customer, id: 145) }.to raise_error QboApi::NotImplementedError
    end
  end
end
