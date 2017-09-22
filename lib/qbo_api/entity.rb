class QboApi
  module Entity

    def singular(entity)
      e = snake_to_camel(entity)
      case e
      when 'Classes', 'Class'
        'Class'
      when 'Entitlements', 'Preferences'
        e
      else
        e.chomp('s')
      end
    end

    def entity_path(entity)
      "#{realm_id}/#{singular(entity).downcase}"
    end

    def snake_to_camel(sym)
      sym.to_s.split('_').collect(&:capitalize).join
    end

    def is_transaction_entity?(entity)
      transaction_entities.include?(singular(entity))
    end

    def transaction_entities
      %w{
        Bill
        BillPayment
        CreditMemo
        Deposit
        Estimate
        Invoice
        JournalEntry
        Payment
        Purchase
        PurchaseOrder
        RefundReceipt
        SalesReceipt
        TimeActivity
        Transfer
        VendorCredit
      }
    end

    def is_name_list_entity?(entity)
      name_list_entities.include?(singular(entity))
    end

    def name_list_entities
      %w{
        Account
        Budget
        Class
        CompanyCurrency
        Customer
        Department
        Employee
        Item
        JournalCode
        PaymentMethod
        TaxAgency
        TaxCode
        TaxRate
        TaxService
        Term
        Vendor
      }
    end

    def supporting_entities
      %w{
        Attachable
        Batch
        CompanyInfo
        Entitlements
        ExchangeRate
        Preferences
      }
    end

    def extract_entity_from_query(query, to_sym: false)
      if m = query.match(/from\s+(\w+)(?:$|\s)/i)
        (to_sym ? underscore(m[1]).to_sym : m[1]) if m[1]
      end
    end

    private

    def underscore(entity)
      entity.gsub(/::/, '/')
            .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
            .gsub(/([a-z\d])([A-Z])/,'\1_\2')
            .tr("-", "_")
            .downcase
    end

  end
end
