require 'spec_helper'

describe "QboApi Attachment" do

  it 'for an invoice is successfully created' do
    payload = {
      "AttachableRef":
          [
            {"EntityRef": 
              {
                "type": "Invoice", 
                "value": "75"
              }
            }
          ],
       "FileName": "no_detail.xml",
       "ContentType": "text/xml"
    }
    api = QboApi.new(creds.to_h)
    VCR.use_cassette("qbo_api/create/attachment_for_invoice", record: :none) do
      response = api.upload_attachment(payload: payload, attachment: fixture_path + '/no_detail.xml')
      expect(response['Id']).to_not be_nil
    end
  end

  it 'fails because estimate value is not found' do
    payload = {
      "AttachableRef":
          [
            {"EntityRef": 
              {
                "type": "Estimate", 
                "value": "75"
              }
            }
          ],
       "FileName": "no_detail.xml",
       "ContentType": "text/xml"
    }
    api = QboApi.new(creds.to_h)
    VCR.use_cassette("qbo_api/error/attachment_estimate", record: :none) do
      response = api.upload_attachment(payload: payload, attachment: fixture_path + '/no_detail.xml')
      expect(response).to include { ['AttachableResponse'].first['Fault'] }
    end
  end
end
