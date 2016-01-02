# QboApi

Ruby client for the QuickBooks Online API version 3.
- Built on top of the excellent Faraday gem. 
- JSON only support. 
  - Please don't ask about XML support. [Intuit has stated](https://github.com/ruckus/quickbooks-ruby/issues/257#issuecomment-126834454) that JSON is the primary data format for the QuickBooks API (v3 and beyond). This gem will specialize in JSON only. The [`quickbooks-ruby`](https://github.com/ruckus/quickbooks-ruby) gem has fantastic support for those who favor XML.
- Features specs built directly against a QuickBooks Online Sandbox via the VCR gem.
- Robust error handling.

## Ruby >= 2.2.2 required

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
  q = account.qbo_account # or wherever you are storing the OAuth creds
  qbo_api = QboApi.new(token: q.token, token_secret: q.secret, realm_id: q.companyid)
```

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

### Search with irregular characters
```ruby
  name = qbo_api.esc "Amy's Bird Sanctuary"
  response = qbo_api.query(%{SELECT * FROM Customer WHERE DisplayName = '#{name}'})
```
### Get an entity by its id
```ruby
  response = qbo_api.get(:customer, 5)
  p response['DisplayName'] # => "Dukes Basketball Camp"
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

### Import/retrieve all
```ruby
  # retrieves all customers
  qbo_api.all(:customers) do |c|
    p "#{c['Id']} #{c['DisplayName']}"
  end

  # retrieves all vendors by groups of 5
  qbo_api.all(:vendor, max: 5) do |v|
    p v['DisplayName']
  end
  
  # retrieves all customers by groups of 2 using a custom select query
  where = "WHERE Id IN ('5', '6', '7', '8', '9', '10')"
  qbo_api.all(:customer, max: 2, select: "SELECT * FROM Customer #{where}") do |c|
    p c['DisplayName']
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

## Spin up an example
- git clone git://github.com/minimul/qbo_api 
- cd qbo_api
- Create a `.env` file
  - DO NOT check in your `.env` file
```ruby
export QBO_API_CONSUMER_KEY=<Your QuickBooks apps consumer key>
export QBO_API_CONSUMER_SECRET=<Your QuickBooks apps consumer secret>
```
- Goto `http://localhost:9393`
- Use the `Connect to QuickBooks` button to connect to your QuickBooks sandbox, which you receive when signing up at [https://developer.intuit.com](https://developer.intuit.com).
- After successfully connecting to your sandbox run:
  - `http://localhost:9393/customer/5`
  - You should see "Dukes Basketball Camp" displayed
- Checkout the example (`example/app.rb`) code to see what is going on.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/minimul/qbo_api.

#### Running the specs
- You at least need to add the following values to a `.env` file
  - DO NOT check in your `.env` file
```ruby
export QBO_API_CONSUMER_KEY=<Your QuickBooks apps consumer key>
export QBO_API_CONSUMER_SECRET=<Your QuickBooks apps consumer secret>
export QBO_API_ACCESS_TOKEN=<OAuth token against your sandbox>
export QBO_API_ACCESS_TOKEN_SECRET=<OAuth token secret against your sandbox>
export QBO_API_COMPANY_ID=<Your sandbox company id>
```
- Note: You can get the access token and secret by using the built-in example.
- To simply run the specs the values don't have to be valid but the variables do need to be set.
- `bundle exec rspec spec`
  
#### Creating new specs or modifying existing spec that have been recorded using the VCR gem.
- All specs that require interaction with the API must be recorded against your personal QuickBooks sandbox.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

