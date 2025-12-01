class Account < ApplicationRecord
  has_prefix_id :acct

  include Billing
  include Domains
  include Transfer
  include Types

  # AMSF CRM extension - each account has one organization
  has_one :organization, dependent: :destroy
end
