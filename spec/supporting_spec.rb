require 'spec_helper'

describe "QboApi::Supporting" do

  let(:api){ QboApi.new(creds.to_h) }

  context ".cdc" do
    it 'should grab estimates via change data capture query' do
      use_cassette("qbo_api/cdc/basic") do
        response = api.cdc(entities: 'estimate', changed_since: '2011-10-10T09:00:00-07:00')
        expect(response['CDCResponse'].size).to eq 1
        ids = response['CDCResponse'][0]['QueryResponse'][0]['Estimate'].collect{ |e| e['Id'] }
        expect(ids).to eq ["48", "46", "41", "100"]
      end
    end
  end

  context ".batch" do
    it 'does 4 operations in one request' do
      use_cassette("qbo_api/batch/basic") do
        response = api.batch(batch_payload)
        batch_response = response['BatchItemResponse']
        expect(batch_response.size).to eq 4
        expect(batch_response.detect{ |b| b["bId"] == "bid1" }["Vendor"]["DisplayName"]).to eq "Smith Family Store#{creds_suffix}"
      end
    end
  end

  context ".reports" do
    it 'for Profit and Loss with query params' do
      use_cassette("qbo_api/reports/profit_and_loss") do
        params = { start_date: '2015-01-01', end_date: '2015-07-31', customer: 1, summarize_column_by: 'Customers' }
        name = 'ProfitAndLoss'
        response = api.reports(name: name, params: params)
        expect(response["Header"]["ReportName"]).to eq name
      end
    end

    it 'for General Ledger with no query params' do
      use_cassette("qbo_api/reports/gl") do
        name = 'GeneralLedger'
        response = api.reports(name: name)
        expect(response["Header"]["ReportName"]).to eq name
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
            "DisplayName": "Smith Family Store#{creds_suffix}"
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


  def creds_suffix
    if creds_type == :oauth2_creds
      "-2"
    else
      ""
    end
  end
end
