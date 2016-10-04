require 'spec_helper'

describe "QboApi Import All entities" do
  context ".all" do
    it 'retrieves all customers' do
      api = QboApi.new(creds.to_h) 
      counter = []
      VCR.use_cassette("qbo_api/all/customers", record: :none) do
        result = api.query("SELECT COUNT(*) FROM Customer")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customers) do |c|
          counter << "#{c['Id']} #{c['DisplayName']}"
        end
        expect(counter.size).to eq count
      end
    end

    it 'retrieves all employees including inactive ones' do
      api = QboApi.new(creds.to_h) 
      counter = []
      VCR.use_cassette("qbo_api/all/employees_including_active", record: :none) do
        result = api.query("SELECT COUNT(*) FROM Employee WHERE Active IN (true, false) ")
        count = result['QueryResponse']['totalCount']
        response = api.all(:employees, inactive: true) do |c|
          counter << "#{c['Id']} #{c['DisplayName']}"
        end
        expect(counter.size).to eq count
      end
    end

    it 'retrieves all vendors by groups of 5' do
      api = QboApi.new(creds.to_h) 
      counter = []
      VCR.use_cassette("qbo_api/all/vendors_by_5", record: :none) do
        result = api.query("SELECT COUNT(*) FROM Vendor")
        count = result['QueryResponse']['totalCount']
        response = api.all(:vendor, max: 5) do |c|
          counter << c['DisplayName']
        end
        expect(counter.size).to eq count
      end
    end

    it 'retrieves all customers, including inactive ones, by groups of 2 by alternate select query' do
      api = QboApi.new(creds.to_h) 
      counter = []
      where = "WHERE Id IN ('5', '6', '7', '8', '9', '10')"
      VCR.use_cassette("qbo_api/all/alt_select", record: :none) do
        result = api.query("SELECT count(*) FROM Customer #{where}")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customer, max: 2, select: "SELECT * FROM Customer #{where}", inactive: true) do |c|
          counter << c['DisplayName']
        end
        expect(counter.size).to eq count
      end
    end

    it 'retrieves sales receipts' do
      api = QboApi.new(creds.to_h) 
      VCR.use_cassette("qbo_api/all/sales_receipts", record: :none) do
        gather = []
        api.all(:sales_receipts) do |s| 
          gather << s['Id']
        end
        expect(gather.first).to eq "47"
      end
    end

  end
end
