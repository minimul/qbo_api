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

  CLIENT_ID = ENV['QBO_API_CLIENT_ID']
  CLIENT_SECRET = ENV['QBO_API_CLIENT_SECRET']

  helpers do
    def oauth2_client
      Rack::OAuth2::Client.new(
        identifier: CLIENT_ID,
        secret: CLIENT_SECRET,
        redirect_uri: redirect_url,
        authorization_endpoint: "https://appcenter.intuit.com/connect/oauth2",
        token_endpoint: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
      )
    end

    def authorize_url(state:)
      oauth2_client.authorization_uri(
        client_id: CLIENT_ID,
        scope: "com.intuit.quickbooks.accounting",
        redirect_uri: redirect_url,
        response_type: "code",
        state: state
      )
    end

    def redirect_url
      "http://localhost:#{PORT}/oauth2-redirect"
    end
  end

  get '/oauth2' do
    session[:state] = SecureRandom.uuid
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
end

OAuth2App.run!
