require 'bundler/inline'

require File.expand_path(File.join('..', 'base'), __FILE__)

install_gems = true
gemfile(install_gems) do
  source 'https://rubygems.org'

  instance_eval(&BASE_GEMS)

  gem 'omniauth'
  gem 'omniauth-quickbooks'
end

instance_eval(&BASE_SETUP)

class OAuthApp < Sinatra::Base
  instance_eval(&BASE_APP_CONFIG)

  CONSUMER_KEY = ENV['QBO_API_CONSUMER_KEY']
  CONSUMER_SECRET = ENV['QBO_API_CONSUMER_SECRET']

  use Rack::Session::Cookie, secret: '34233adasf/qewrq453agqr9(lasfa)'
  use OmniAuth::Builder do
    provider :quickbooks, CONSUMER_KEY, CONSUMER_SECRET
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

  get '/auth/quickbooks/callback' do
    auth = env["omniauth.auth"][:credentials]
    session[:token] = auth[:token]
    session[:secret] = auth[:secret]
    session[:realm_id] = params['realmId']
    '<!DOCTYPE html><html lang="en"><head></head><body><script>window.opener.location.reload(); window.close();</script></body></html>'
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
end

OAuthApp.run!
