class QboApi
  module Attachment

    def read_attachment(id:)
      raw_response = connection.get do |request|
        request.url "#{realm_id}/attachable/#{id}"
      end
      response(raw_response, entity: :attachable)
    end

    def upload_attachment(payload:, attachment:)
      content_type = payload['ContentType'] || payload[:ContentType]
      file_name = payload['FileName'] || payload[:FileName]
      raw_response = attachment_connection.post do |request|
        request.url "#{realm_id}/upload"
        request.body = {
            'file_metadata_01':
                Faraday::UploadIO.new(StringIO.new(payload.to_json), 'application/json', 'attachment.json'),
            'file_content_01':
                Faraday::UploadIO.new(attachment, content_type, file_name)
        }
      end
      response(raw_response, entity: :attachable)
    end

    # The `attachable` must be the full payload returned in the read response
    def delete_attachment(attachable:)
      raw_response = connection.post do |request|
        request.url "#{realm_id}/attachable?operation=delete"
        request.body = attachable.to_json
      end

      response(raw_response, entity: :attachable)
    end

    def attachment_connection
      @attachment_connection ||= authorized_multipart_connection(endpoint_url)
    end

  end
end

