require 'bundler/inline'

require File.expand_path(File.join('..', 'base'), __FILE__)

install_gems = true
gemfile(install_gems) do
  source 'https://rubygems.org'

  instance_eval(&BASE_GEMS)

  gem 'rack-oauth2'
end

instance_eval(&BASE_SETUP)

class OAuth2App < Sinatra::Base
  instance_eval(&BASE_APP_CONFIG)

  # OAuth2 credentials
  CLIENT_ID = ENV['QBO_API_CLIENT_ID']
  CLIENT_SECRET = ENV['QBO_API_CLIENT_SECRET']
  # OAuth2 authorization endpoints
  REDIRECT_URI = "http://localhost:#{PORT}/oauth2-redirect"
  AUTHORIZATION_ENDPOINT = "https://appcenter.intuit.com/connect/oauth2"
  TOKEN_ENDPOINT = "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
  #

  helpers do
    def oauth2_creds
      {
        identifier: CLIENT_ID,
        secret: CLIENT_SECRET,
        redirect_uri: REDIRECT_URI,
        authorization_endpoint: AUTHORIZATION_ENDPOINT,
        token_endpoint: TOKEN_ENDPOINT
      }
    end

    def oauth2_client
      Rack::OAuth2::Client.new(oauth2_creds)
    end
  end

  get '/oauth2' do
    session[:state] = SecureRandom.uuid
    url = 'https://appcenter.intuit.com'
    authorization_endpoint = '/connect/oauth2'
    api = QboApi.new(realm_id: ENV.fetch("QBO_API_COMPANY_ID"))
    connection = api.build_connection(url) do |conn|
      api.send(:add_exception_middleware, conn)
      api.send(:add_connection_adapter, conn)
    end
    raw_request = connection.get do |req|
      params = {
        client_id: CLIENT_ID,
        scope: "com.intuit.quickbooks.accounting",
        response_type: "code",
        state: session[:state],
        redirect_uri: REDIRECT_URI
      }
      req.url authorization_endpoint, params
    end

    redirect raw_request.env[:url]
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
end

OAuth2App.run!
