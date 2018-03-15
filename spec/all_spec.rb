require 'spec_helper'

describe "QboApi Import All entities" do
  let(:api){ QboApi.new(creds.to_h) }
  
  context ".all" do
    context "backwards compatability (with block)" do
      it 'retrieves all customers' do
        counter = []
        use_cassette("qbo_api/all/customers") do
          result = api.query("SELECT COUNT(*) FROM Customer")
          count = result['QueryResponse']['totalCount']
          response = api.all(:customers) do |c|
            counter << "#{c['Id']} #{c['DisplayName']}"
          end
          expect(counter.size).to eq count
        end
      end
    end

    it 'retrieves all customers' do
      use_cassette("qbo_api/all/customers") do
        result = api.query("SELECT COUNT(*) FROM Customer")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customers)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all employees including inactive ones' do
      use_cassette("qbo_api/all/employees_including_active") do
        result = api.query("SELECT COUNT(*) FROM Employee WHERE Active IN (true, false) ")
        count = result['QueryResponse']['totalCount']
        response = api.all(:employees, inactive: true)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all vendors by groups of 5' do
      use_cassette("qbo_api/all/vendors_by_5") do
        result = api.query("SELECT COUNT(*) FROM Vendor")
        count = result['QueryResponse']['totalCount']
        response = api.all(:vendor, max: 5)
        expect(response.count).to eq count
      end
    end

    it 'retrieves all customers, including inactive ones, by groups of 2 by alternate select query' do
      where = "WHERE Id IN ('5', '6', '7', '8', '9', '10')"
      use_cassette("qbo_api/all/alt_select") do
        result = api.query("SELECT count(*) FROM Customer #{where}")
        count = result['QueryResponse']['totalCount']
        response = api.all(:customer, max: 2, select: "SELECT * FROM Customer #{where}", inactive: true)
        expect(response.count).to eq count
      end
    end

    it 'retrieves sales receipts' do
      use_cassette("qbo_api/all/sales_receipts") do
        first_id = api.all(:sales_receipts).first['Id']
        expect(first_id).to eq "47"
      end
    end

  end
end
