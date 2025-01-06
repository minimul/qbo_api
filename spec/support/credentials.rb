require 'dotenv'

Dotenv.load

def creds
  {
    access_token: ENV['QBO_API_ACCESS_TOKEN'],
    realm_id: ENV['QBO_API_COMPANY_ID']
  }
end
