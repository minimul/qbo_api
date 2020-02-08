require 'spec_helper'

describe "QboApi Attachment" do

  let(:api){ QboApi.new(creds.to_h) }

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
    use_cassette("qbo_api/attachment/create_for_invoice") do
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
    use_cassette("qbo_api/attachment/error_estimate") do
      response = api.upload_attachment(payload: payload, attachment: fixture_path + '/no_detail.xml')
      expect(response).to include { ['AttachableResponse'].first['Fault'] }
    end
  end

  it 'reads an attachment' do
    id = '5000000000000149663'
    use_cassette('qbo_api/attachment/read_attachment') do
      response = api.read_attachment(id: id)
      expect(response['Id']).to_not be_nil
      expect(response['Note']).to eq 'This is an attached note'
    end
  end

  it 'deletes an attachment' do
    attachable = {
      "SyncToken" => "0",
      "domain" => "QBO",
      "AttachableRef" => [
        {
          "IncludeOnSend" => false,
          "EntityRef" => {
            "type" => "Invoice",
            "value" => "95"
          }
        }
      ],
      "Note" => "This is an attached note.",
      "sparse" => false,
      "Id" => "200900000000000008541",
      "MetaData" => {
        "CreateTime" => "2015-11-17T11:05:15-08:00",
        "LastUpdatedTime" => "2015-11-17T11:05:15-08:00"
      }
    }
    use_cassette('qbo_api/attachment/delete_attachment') do
      response = api.delete_attachment(attachable: attachable)
      expect(response['status']).to eq 'Deleted'
      expect(response['Id']).to eq '200900000000000008541'
    end
  end
end
