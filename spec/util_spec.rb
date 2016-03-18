require 'spec_helper'

describe QboApi::Util do

  it 'allow string to pass thru cdc_time' do
    api = QboApi.new(creds.to_h) 
    expect(api.cdc_time("str")).to eq "str"
  end

  it 'convert Time objects to proper CDC "changed since" time stamp' do
    api = QboApi.new(creds.to_h)
    expect(api.cdc_time(Time.now)).to match /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}-\d{2}:\d{2}$/
  end
end
