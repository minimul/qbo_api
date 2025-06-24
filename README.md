# QboApi

Ruby client for the QuickBooks Online API version 3.
- JSON only support.
  - Please don't ask about XML support. [Intuit has stated](https://github.com/ruckus/quickbooks-ruby/issues/257#issuecomment-126834454) that JSON is the primary data format for the QuickBooks API (v3 and beyond). This gem will specialize in JSON only. The [`quickbooks-ruby`](https://github.com/ruckus/quickbooks-ruby) gem has fantastic support for those who favor XML.
- Features specs built directly against a QuickBooks Online Sandbox via the VCR gem.
- Robust error handling.

## The Book

<a href="https://leanpub.com/minimul-qbo-guide-vol-1" target="_blank">
  <img src="http://img.minimul.com/shared/crow-cover.png" alt="The QBO book">
</a>


## Ruby >= 2.6 required

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'qbo_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qbo_api

## Usage

### Initialize
```ruby
  qbo_api = QboApi.new(access_token: 'REWR342532asdfae!$4asdfa', realm_id: 32095430444)
- qbo_api.get :customer, 1
```

### Super fast way to use QboApi as long as Ruby >= 2.5 is installed
```
- cd ~/<local dir>
- git clone git@github.com:minimul/qbo_api.git && cd qbo_api
- bundle
- bin/console
- QboApi.production = true
- qbo_api = QboApi.new(access_token: "qyprd2uvCOdRq8xzoSSiiiiii", realm_id: "12314xxxxxx7")
- qbo_api.get :customer, 1
```

### DateTime serialization
Some QBO entities have attributes of type DateTime (e.g., Time Activities with StartTime and EndTime). All DateTimes passed to the QBO API must be serialized in ISO 8601 format.
If ActiveSupport is loaded, you can achieve proper serialization with the following configuration:
```ruby
ActiveSupport::JSON::Encoding.use_standard_json_time_format = true
ActiveSupport::JSON::Encoding.time_precision = 0
```
If you're not using ActiveSupport, you'll need to use `#iso8601` method to convert your `Time`/`DateTime` instances to strings before passing them to a QboApi instance. Failure to do so will result in a raised QboApi::BadRequest exception.

### Configuration options
- By default this client runs against a QBO sandbox. To run against the production QBO API URL do:
```ruby
QboApi.production = true
```
- Logging:
```ruby
QboApi.log = true
```
- To change logging target from `$stdout` e.g.
```ruby
QboApi.logger = Rails.logger
```
- To run all requests with unique [RequestIds](https://developer.intuit.com/hub/blog/2015/04/06/15346).
```ruby
QboApi.request_id = true
```
- To run individual requests with a RequestId then do something like this:
```ruby
  resp = qbo_api.create(:bill, payload: bill_hash, params: { requestid: qbo_api.uuid })
  # Works with .get, .create, .update, .query methods
```
- By default, this client runs against the current "base" or major version of the QBO API. This client does not run against the latest QBO API [minor version](https://developer.intuit.com/app/developer/qbo/docs/learn/explore-the-quickbooks-online-api/minor-versions) by default. To run all requests with a specific minor version, you must specify it:
```ruby
QboApi.minor_version = 8
```
- To run individual requests with a minor version then do something like this:
```ruby
  resp = qbo_api.get(:item, 8, params: { minorversion: 8 })
  # Works with .get, .create, .update, .query methods
```

### Create
```ruby
  invoice = {
    "Line": [
      {
        "Amount": 100.00,
        "DetailType": "SalesItemLineDetail",
        "SalesItemLineDetail": {
          "ItemRef": {
            "value": "1",
            "name": "Services"
          }
        }
      }
    ],
    "CustomerRef": {
      "value": "1"
    }
  }
  response = qbo_api.create(:invoice, payload: invoice)
  p response['Id'] # => 65
```

### Update
```ruby
  customer = {
    DisplayName: 'Jack Doe',
    PrimaryPhone: {
      FreeFormNumber: "(415) 444-1234"
    }
  }
  response = qbo_api.update(:customer, id: 60, payload: customer)
  p response.fetch('PrimaryPhone').fetch('FreeFormNumber') # => "(415) 444-1234"
```

### Delete (only works for transaction entities)
```ruby
  response = qbo_api.delete(:invoice, id: 145)
  p response['status'] # => "Deleted"
```

NOTE: If you are deleting a journal entry you have to use the following syntax with the underscore, even though this is inconsistent with how you create journal entries.
```ruby
  response = qbo_api.delete(:journal_entry, id: 145)
  p response['status'] # => "Deleted"
```

### Deactivate (only works for name list entities)
```ruby
  response = qbo_api.deactivate(:employee, id: 55)
  p response['Active'] # => false
```

### Get an entity by its id
```ruby
  response = qbo_api.get(:customer, 5)
  p response['DisplayName'] # => "Dukes Basketball Camp"
```

### Get an entity by one of its filter attributes
```ruby
  response = qbo_api.get(:customer, ["DisplayName", "Dukes Basketball Camp"])
  p response['Id'] # => 5
```

### Get an entity by one of its filter attributes using a LIKE search
```ruby
  response = qbo_api.get(:customer, ["DisplayName", "LIKE", "Dukes%"])
  p response['Id'] # => 5
```

### Get an entity by one of its filter attributes using a IN search
```ruby
  response = qbo_api.get(:vendor, ["DisplayName", "IN", "(true, false)"])
  p response.size # => 28
```

### Import/retrieve all
*Note: There is some overlap with the `all` and the `get` methods. The `get` method is limited to 1000 results where the `all` method will return all the results no matter the number.*
```ruby
  # retrieves all active customers
  qbo_api.all(:customers).each do |c|
    p "#{c['Id']} #{c['DisplayName']}"
  end

  # retrieves all active or inactive employees
  qbo_api.all(:employees, inactive: true).each do |e|
    p "#{e['Id']} #{e['DisplayName']}"
  end

  # retrieves all vendors by groups of 5
  qbo_api.all(:vendor, max: 5).each do |v|
    p v['DisplayName']
  end

  # retrieves all customers by groups of 2 using a custom select query
  where = "WHERE Id IN ('5', '6', '7', '8', '9', '10')"
  qbo_api.all(:customer, max: 2, select: "SELECT * FROM Customer #{where}").each do |c|
    p c['DisplayName']
  end
```

#### Note: .all() returns a Ruby Enumerator

```
api.all(:clients).take(50).each { |c| p c["Id"] }
api.all(:clients).count
api.all(:clients).first
api.all(:clients).to_a
```

### Search with irregular characters
```ruby
  # Use the .esc() method
  name = qbo_api.esc "Amy's Bird Sanctuary"
  response = qbo_api.query(%{SELECT * FROM Customer WHERE DisplayName = '#{name}'})
  # OR USE .get() method, which will automatically escape
  response = qbo_api.get(:customer, ["DisplayName", "Amy's Bird Sanctuary"])
  p response['Id'] # => 1
```


### Email a transaction entity
```ruby
api.send_invoice(invoice_id: 1, email_address: 'billy@joe.com')
```

### Uploading an attachment
```ruby
  payload = {"AttachableRef":
              [
                {"EntityRef":
                  {
                    "type": "Invoice",
                    "value": "111"
                  }
                }
              ],
             "FileName": "test.txt",
             "ContentType": "text/plain"
            }
  # `attachment` can be either an IO stream or string path to a local file
  response = qbo_api.upload_attachment(payload: payload, attachment: '/tmp/test.txt')
  p response['Id'] # => 5000000000000091308
```

Be aware that any errors will not raise a `QboApi::Error`, but will be returned in the following format:
```ruby
  {"AttachableResponse"=>
    [{"Fault"=>
       {"Error"=>
         [{"Message"=>"Object Not Found",
           "Detail"=>
            "Object Not Found : Something you're trying to use has been made inactive. Check the fields with accounts, customers, items, vendors or employees.",
           "code"=>"610",
           "element"=>""}],
        "type"=>"ValidationFault"}}],
   "time"=>"2018-01-03T13:06:31.406-08:00"}
```

### Change data capture (CDC) query
```ruby
  response = qbo_api.cdc(entities: 'estimate', changed_since: '2011-10-10T09:00:00-07:00')
  # You can also send in a Time object e.g. changed_since: Time.now
  expect(response['CDCResponse'].size).to eq 1
  ids = response['CDCResponse'][0]['QueryResponse'][0]['Estimate'].collect{ |e| e['Id'] }
  p ids
```

### Batch operations (limit 30 operations in 1 batch request)
```ruby
  payload = {
      "BatchItemRequest":
      [
        {
          "bId": "bid1",
          "operation": "create",
          "Vendor": {
            "DisplayName": "Smith Family Store"
          }
        }, {
          "bId": "bid2",
          "operation": "delete",
          "Invoice": {
            "Id": "129",
            "SyncToken": "0"
          }
        }
      ]
  }
  response = qbo_api.batch(payload)
  expect(response['BatchItemResponse'].size).to eq 2
  expect(batch_response.detect{ |b| b["bId"] == "bid1" }["Vendor"]["DisplayName"]).to eq "Smith Family Store"
```

### Reports

```ruby
        params = { start_date: '2015-01-01', end_date: '2015-07-31', customer: 1, summarize_column_by: 'Customers' }
        response = qbo_api.reports(name: 'ProfitAndLoss', params: params)
        p response["Header"]["ReportName"]) #=> 'ProfitAndLoss'
```

### Respond to an error
```ruby
  customer = { DisplayName: 'Weiskopf Consulting' }
  begin
    response = qbo_api.create(:customer, payload: customer)
  rescue QboApi::BadRequest => e
    if e.message =~ /Another customer already exists with this name/
      # Query for Id using DisplayName
      # Do an qbo_api.update instead
    end
  end
```

### What kind of QuickBooks entity?
```ruby
  p qbo_api.is_transaction_entity?(:invoice) # => true
  # Plural is supported as well
  p qbo_api.is_transaction_entity?(:invoices) # => true
  p qbo_api.is_transaction_entity?(:customer) # => false
  p qbo_api.is_name_list_entity?(:vendors) # => true
```

### Download Quickbooks PDF
A quickbooks supplied PDF can be downloaded for api endpoints which offer a PDF.
```ruby
qbo_api.get_pdf(:invoice, 121) # produces a pdf stream.
```
The PDF stream can then be saved using your preferred method.
```ruby
# example using Ruby on Rails with ActiveStorage
class Invoice
  has_one_attached :pdf_file
end
invoice_number = 121
pdf_data = qbo_api.get_pdf(:invoice, invoice_numer) # returns raw pdf stream
pdf_io = StringIO.new(pdf_data) # convert to a StringIO object
filename = "invoice_no_#{invoice_number}"

invoice.pdf_file.attach(
    io: pdf_io,
    filename: filename,
    content_type: 'application/pdf'
)
```

```ruby
# plain ruby example
invoice_number = 121
pdf_data = qbo_api.get_pdf(:invoice, invoice_numer) # returns raw pdf stream
filename = "invoice_no_#{invoice_number}.pdf"

File.write(filename, pdf_data)
```
## Spin up an example
- <a href="http://minimul.com/access-the-quickbooks-online-api-with-oauth2.html" target="_blank">Check out this article on spinning up the example</a>.

- Create a Intuit developer account at [https://developer.intuit.com](https://developer.intuit.com)
- Create an app in the intuit developer backend
  - Go to [myapps](https://developer.intuit.com/app/developer/myapps)
  - Create an app with both the `Accounting` & `Payments` selected.

- Setup the app and gather credentials
  - Go to the [Development Dashboard](https://developer.intuit.com/app/developer/dashboard)
  - Click on your App name
  - Click "Keys & credentials" under Development Settings in left menu
  - Copy the 'Client ID' and the 'Client Secret'
  - Add a Redirect URI: `http://localhost:9393/oauth2-redirect` (or whatever PORT= is in your .env)
  - Create a new Sandbox Company by clicking on "View Sandbox companies"
    Don't use it for anything else besides testing this app.
  - Copy the 'Company ID' for use later
    1. Within 'Sandbox Company_US_1' click on the COG -> Additional info
    2. Copy the 'Company ID'
  
- Setup qbo_api
  - `git clone git://github.com/minimul/qbo_api && cd qbo_api`
  - `bundle`

- Create a `.env` file
  - `cp .env.example_app.oauth2 .env`
  - Edit your .env and enter the following
    ```
    export QBO_API_CLIENT_ID=[YOUR CLIENT ID]
    export QBO_API_CLIENT_SECRET=[YOUR CLIENT SECRET]
    export QBO_API_COMPANY_ID=[YOUR COMPANY ID]
    ```

- Start up the example app and test
  - `ruby example/oauth2.rb`
  - Go to `http://localhost:9393/oauth2`
  - Use the `Connect to QuickBooks` button to connect to your QuickBooks sandbox, which you receive when signing up at [https://developer.intuit.com](https://developer.intuit.com).
  - After successfully connecting to your sandbox go to `http://localhost:9393/oauth2/customer/5`
  - You should see "Dukes Basketball Camp" displayed

- Checkout [`example/oauth2.rb`](https://github.com/minimul/qbo_api/blob/master/example/oauth2.rb)
  to see what is going on under the hood.

## Webhooks
- <a href="http://minimul.com/getting-started-with-quickbooks-online-webhooks.html" target="_blank">Check out this tutorial and screencast on handling a webhook request</a>. Also checkout [`example/app.rb`](https://github.com/minimul/qbo_api/blob/master/example/app.rb) for the request handling code.

See https://www.twilio.com/blog/2015/09/6-awesome-reasons-to-use-ngrok-when-testing-webhooks.html
for how to install ngrok and what it is.

- With the example app running, run:
  `ngrok http 9393 -subdomain=somereasonablyuniquenamehere`

- Go to the [`Development` tab](https://developer.intuit.com/v2/ui#/app/dashboard)
- Add a webhook, Select all triggers and enter the https url from the ngrok output
  `https://somereasonablyuniquenamehere/webhooks`

- After saving the webhook, click 'show token'.
  Add the token to your .env as QBO_API_VERIFIER_TOKEN

- In another tab, create a customer via the API:
  `bundle exec ruby -rqbo_api -rdotenv -e 'Dotenv.load; p QboApi.new(access_token: ENV.fetch("QBO_API_ACCESS_TOKEN"), realm_id: ENV.fetch("QBO_API_COMPANY_ID")).create(:customer, payload: { DisplayName: "TestCustomer" })'`
  (You'll also need to have added the QBO_API_COMPANY_ID and QBO_API_ACCESS_TOKEN to your .env)

  There could be a delay of up to a minute before the webhook fires.

  It'll appear in your logs like:
  ```
  {"eventNotifications"=>[{"realmId"=>"XXXX", "dataChangeEvent"=>{"entities"=>[{"name"=>"Customer", "id"=>"62", "operation"=>"Create", "lastUpdated"=>"2018-04-08T04:14:39.000Z"}]}}]}
  Verified: true
  "POST /webhooks HTTP/1.1" 200 - 0.0013
  ```

### Just For Hackers

- Using the build_connection method
```
connection = build_connection('https://oauth.platform.intuit.com', headers: { 'Accept' => 'application/json' }) do |conn|
  conn.basic_auth(client_id, client_secret)
  conn.request :url_encoded # application/x-www-form-urlencoded
  conn.response :json
  conn.use QboApi::RaiseHttpException
end

raw_response = connection.post do |req|
  req.body = { grant_type: :refresh_token, refresh_token: current_refresh_token }
  req.url '/oauth2/v1/tokens/bearer'
end
```
- Once your .env file is completely filled out you can use the console to play around in your sandbox
```
bin/console test
>> @qbo_api.get :customer, 1
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/minimul/qbo_api.

#### Running the specs
- <a href="http://minimul.com/the-modern-ruby-quickbooks-client-part-2.html" target="_blank">Check out this tutorial and screencast on running the specs</a>
- `git clone git://github.com/minimul/qbo_api && cd qbo_api`
- `bundle`
- Create a `.env` file
  - `cp .env.test .env`
  - Update it if your are making HTTP requests.
- `bundle exec rspec spec/`

#### Creating new specs or modifying existing spec that have been recorded using the VCR gem.
- All specs that require interaction with the API must be recorded against your personal QuickBooks sandbox. More coming on how to create or modifying existing specs against your sandbox.
- <a href="http://minimul.com/the-modern-ruby-quickbooks-client-contributing.html" target="_blank">Check out this tutorial and screencast on contributing to qbo_api</a>.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

