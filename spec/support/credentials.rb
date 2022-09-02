require 'dotenv'

Dotenv.load

def creds
  oauth2_creds.to_h
end

def oauth2_creds
  OpenStruct.new({
    access_token: ENV['QBO_API_ACCESS_TOKEN'],
    realm_id: ENV['QBO_API_COMPANY_ID']
  })
end
