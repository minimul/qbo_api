require 'spec_helper'

describe QboApi do

  let(:api){ QboApi.new(creds.to_h) }

  it 'has a version number' do
    expect(QboApi::VERSION).not_to be nil
  end

  it '.snake_to_camel' do
    res = %w(SalesReceipt CreditMemo Customer)
    %i(sales_receipt credit_memo customer).each_with_index do |s, index|
      expect(api.snake_to_camel(s)).to eq res[index]
    end
  end

  it '.singular' do
    res = %w(Invoice Preferences Entitlements Class Vendor)
    %i(invoices preferences entitlements classes vendor).each_with_index do |s, index|
      expect(api.singular(s)).to eq res[index]
    end
  end

  it '.is_transaction_entity?' do
    expect(api.is_transaction_entity?(:invoice)).to be true
    expect(api.is_transaction_entity?(:invoices)).to be true
    expect(api.is_transaction_entity?(:customer)).to be false
    expect(api.is_transaction_entity?(:refund_receipt)).to be true
  end

  it '.is_name_list_entity?' do
    expect(api.is_name_list_entity?(:vendors)).to be true
    expect(api.is_name_list_entity?(:classes)).to be true
    expect(api.is_name_list_entity?(:payment_method)).to be true
    expect(api.is_name_list_entity?(:refund_receipt)).to be false
  end

  it '.extract_entity_from_query' do
    expect(api.extract_entity_from_query('Select * FROM Invoice WHERE')).to eq "Invoice"
    expect(api.extract_entity_from_query('Select count(*) fROM PurchaseOrder WHERE DisplayName =')).to eq "PurchaseOrder"
    expect(api.extract_entity_from_query('Select # invoice WHERE')).to be nil
    expect(api.extract_entity_from_query(%{Select * FROM SalesReceipt WHERE FamilyName = 'Johnson'}, to_sym: true)).to eq :sales_receipt
  end

  it '.get_endpoint' do
    expect(api.send(:get_endpoint)).to eq QboApi::V3_ENDPOINT_BASE_URL
    QboApi.production = true
    expect(api.send(:get_endpoint)).to_not match /sandbox/
    new_api = QboApi.new(creds.to_h)
    expect(new_api.send(:get_endpoint)).to_not match /sandbox/
    QboApi.production = false
    api = QboApi.new(creds.to_h.merge(endpoint: :payments))
    expect(api.send(:get_endpoint)).to eq QboApi::PAYMENTS_API_BASE_URL
    QboApi.production = true
    expect(api.send(:get_endpoint)).to eq QboApi::PAYMENTS_API_BASE_URL.sub("sandbox.", "")
    QboApi.production = false # Always end with = false
  end

end
