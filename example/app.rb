require "bundler/setup"
require 'sinatra'
require 'json'
require 'openssl'
require 'base64'
require 'omniauth'
require 'omniauth-quickbooks'
require 'dotenv'
require 'qbo_api'
Dotenv.load "#{__dir__}/../.env"

PORT  = 9393
CONSUMER_KEY = ENV['QBO_API_CONSUMER_KEY']
CONSUMER_SECRET = ENV['QBO_API_CONSUMER_SECRET']
VERIFIER_TOKEN = ENV['QBO_API_VERIFIER_TOKEN']

set :port, PORT
use Rack::Session::Cookie, secret: '34233adasf'
use OmniAuth::Builder do
  provider :quickbooks, CONSUMER_KEY, CONSUMER_SECRET
end

helpers do
  def verify_webhook(data, hmac_header)
    digest  = OpenSSL::Digest.new('sha256')
    calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, VERIFIER_TOKEN, data)).strip
    calculated_hmac == hmac_header
  end
end

get '/' do
  @app_center = QboApi::APP_CENTER_BASE
  @auth_data = oauth_data
  @port = PORT
  erb :index
end

get '/customer/:id' do
  if session[:token]
    api = QboApi.new(oauth_data)
    @resp = api.get :customer, params[:id]
  end
  erb :customer
end

post '/webhooks' do
  request.body.rewind
  data = request.body.read
  puts JSON.parse data
  verified = verify_webhook(data, env['HTTP_INTUIT_SIGNATURE'])
  puts "Verified: #{verified}"
end

def oauth_data
  {
    consumer_key: CONSUMER_KEY,
    consumer_secret: CONSUMER_SECRET,
    token: session[:token],
    token_secret: session[:secret],
    realm_id: session[:realm_id]
  }
end

get '/auth/quickbooks/callback' do
  auth = env["omniauth.auth"][:credentials]
  session[:token] = auth[:token] 
  session[:secret] = auth[:secret] 
  session[:realm_id] = params['realmId']
  '<!DOCTYPE html><html lang="en"><head></head><body><script>window.opener.location.reload(); window.close();</script></body></html>'
end
