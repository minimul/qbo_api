class QboApi
  module Attachment

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

    private

    def attachment_connection
      return @attachment_connection if @attachment_connection
      multipart_connection = connection.dup
      multipart_connection.headers['Content-Type'] = 'multipart/form-data'
      multipart_middleware_index = multipart_connection.builder.handlers.index(Faraday::Request::UrlEncoded) || 1
      multipart_connection.builder.insert(multipart_middleware_index, Faraday::Request::Multipart)
      @attachment_connection = multipart_connection
    end

  end
end

