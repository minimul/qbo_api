require 'dotenv'

Dotenv.load

def creds
  case creds_type
  when :oauth2_creds then oauth2_creds
  when :oauth1_creds then oauth1_creds
  else fail NotImplementedError, "No creds configured for type: '#{creds_type.inspect}'"
  end
end

def creds_type
  if ENV['QBO_API_OAUTH2_ACCESS_TOKEN']
    :oauth2_creds
  else
    :oauth1_creds
  end
end

def oauth1_creds
    OpenStruct.new(
      {
        consumer_key: ENV['QBO_API_CONSUMER_KEY'],
        consumer_secret: ENV['QBO_API_CONSUMER_SECRET'],
        token: ENV['QBO_API_ACCESS_TOKEN'],
        token_secret: ENV['QBO_API_ACCESS_TOKEN_SECRET'],
        realm_id: ENV['QBO_API_COMPANY_ID']
      }
    )
end

def oauth2_creds
  OpenStruct.new(
    {
      access_token: ENV['QBO_API_OAUTH2_ACCESS_TOKEN'],
      realm_id: ENV['QBO_API_COMPANY_ID']
    }
  )
end
