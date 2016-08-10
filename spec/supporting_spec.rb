require 'spec_helper'

describe "QboApi::Supporting" do
  context ".batch" do
    it 'does 4 operations in one request' do
      api = QboApi.new(creds.to_h)
      VCR.use_cassette("qbo_api/batch/basic", record: :none) do
        response = api.batch(batch_payload)
        batch_response = response['BatchItemResponse']
        expect(batch_response.size).to eq 4
        expect(batch_response.detect{ |b| b["bId"] == "bid1" }["Vendor"]["DisplayName"]).to eq "Smith Family Store" 
      end
    end
  end

  def batch_payload
    {
      "BatchItemRequest": 
      [
        {
          "bId": "bid1",
          "operation": "create",
          "Vendor": {
            "DisplayName": "Smith Family Store"
          }
        }, {
          "bId": "bid2",
          "operation": "delete",
          "Invoice": {
            "Id": "129",
            "SyncToken": "0"
          }
        }, { 
          "bId": "bid3",
          "operation": "update",
          "SalesReceipt": {
            "domain": "QBO",
            "sparse": true,
            "Id": "11",
            "SyncToken": "0",
            "PrivateNote":"A private note."       
          }
        }, {
          "bId": "bid4",
          "Query": "select * from SalesReceipt where TotalAmt > '300.00'"
        }
      ]
    }

  end
end
