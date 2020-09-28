require 'spec_helper'

describe "QboApi Attachment" do
  let(:api){ QboApi.new(creds) }

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
    use_cassette("attachment/create_for_invoice") do
      response = api.upload_attachment(payload: payload, attachment: fixture_path + '/no_detail.xml')
      # p response['Id']
      expect(response['Id']).to_not be_nil
    end
  end

  it 'reads an attachment' do
    id = '5000000000000503624' # use the id from the attachment/create_for_invoice cassette
    use_cassette('attachment/read_attachment') do
      response = api.read_attachment(id: id)
      expect(response['Id']).to_not be_nil
      expect(response['FileName']).to eq 'no_detail.xml'
    end
  end

  it 'deletes an attachment' do
    # After successfully recording the create are read attachments
    # now delete the attachment using the id from the create_for_invoice cassette
    id = '5000000000000503624'
    use_cassette('attachment/delete_attachment') do
      response = api.delete_attachment(attachable: {"Id" => id})
      expect(response['status']).to eq 'Deleted'
      expect(response['Id']).to eq id
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
    use_cassette("attachment/error_estimate") do
      response = api.upload_attachment(payload: payload, attachment: fixture_path + '/no_detail.xml')
      expect(response).to include { ['AttachableResponse'].first['Fault'] }
    end
  end
end
