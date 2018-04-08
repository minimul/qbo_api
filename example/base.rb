BASE_GEMS = proc do
  gem 'qbo_api', path: '.'
  # This app
  gem 'sinatra'
  gem 'sinatra-contrib'

  # Creds from ../.env
  gem 'dotenv'
end

BASE_SETUP = proc do
  # Webhook support
  require 'json'
  require 'openssl'
  require 'base64'

  Dotenv.load "#{__dir__}/../.env"
end

BASE_APP_CONFIG = proc do
  PORT  = ENV.fetch("PORT", 9393)
  # WebHook verifier token
  VERIFIER_TOKEN = ENV['QBO_API_VERIFIER_TOKEN']

  configure do
    $VERBOSE = nil # silence redefined constant warning
    register Sinatra::Reloader
  end

  set :sessions, :true
  set :port, PORT

  before do
    # Rewrite trailing slashes
    next unless request.path_info =~ %r{/(.+)/$}
    redirect(Regexp.last_match[1], 301)
  end

  post '/webhooks' do
    request.body.rewind
    data = request.body.read
    puts JSON.parse data
    verified = verify_webhook(data, env['HTTP_INTUIT_SIGNATURE'])
    puts "Verified: #{verified}"
  end

  helpers do
    def verify_webhook(data, hmac_header)
      digest  = OpenSSL::Digest.new('sha256')
      calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, VERIFIER_TOKEN, data)).strip
      calculated_hmac == hmac_header
    end
  end
end
