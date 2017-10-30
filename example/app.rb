require "bundler/setup"
require 'sinatra'
require 'json'
require 'openssl'
require 'base64'
require 'omniauth'
require 'omniauth-quickbooks'
require 'dotenv'
require 'rack/oauth2'
require 'qbo_api'

Dotenv.load "#{__dir__}/../.env"

PORT  = ENV.fetch("PORT", 9393)
CONSUMER_KEY = ENV['QBO_API_CONSUMER_KEY']
CONSUMER_SECRET = ENV['QBO_API_CONSUMER_SECRET']
CLIENT_ID = ENV['QBO_API_CLIENT_ID']
CLIENT_SECRET = ENV['QBO_API_CLIENT_SECRET']
VERIFIER_TOKEN = ENV['QBO_API_VERIFIER_TOKEN']

set :port, PORT
use Rack::Session::Cookie, secret: '34233adasf/qewrq453agqr9(lasfa)'
use OmniAuth::Builder do
  provider :quickbooks, CONSUMER_KEY, CONSUMER_SECRET
end

helpers do
  def verify_webhook(data, hmac_header)
    digest  = OpenSSL::Digest.new('sha256')
    calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, VERIFIER_TOKEN, data)).strip
    calculated_hmac == hmac_header
  end

  def oauth2_client
    client = Rack::OAuth2::Client.new(
      identifier: CLIENT_ID,
      secret: CLIENT_SECRET,
      redirect_uri: "http://localhost:#{PORT}/oauth2-redirect",
      authorization_endpoint: "https://appcenter.intuit.com/connect/oauth2",
      token_endpoint: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
    )
  end
end

get '/' do
  @app_center = QboApi::APP_CENTER_BASE
  @auth_data = oauth_data
  @port = PORT
  erb :index
end

get '/oauth2' do
  session[:state] = SecureRandom.uuid
  @client = oauth2_client
  erb :oauth2
end

get '/oauth2-redirect' do
  state = params[:state]
  error = params[:error]
  code = params[:code]
  if state == session[:state]
    client = oauth2_client
    client.authorization_code = code
    if resp = client.access_token!
      session[:refresh_token] = resp.refresh_token
      session[:access_token] = resp.access_token
      session[:realm_id] = params[:realmId]
      erb :oauth2_redirect
    else
      "Something went wrong. Try the process again"
    end
  else
    "Error: #{error}"
  end
end

get '/oauth2/customer/:id' do
  if access_token = session[:access_token]
    api = QboApi.new(access_token: access_token, realm_id: session[:realm_id])
    @resp = api.get :customer, params[:id]
  end
  erb :customer
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
