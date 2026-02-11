class Account < ApplicationRecord
  has_prefix_id :acct

  include Billing
  include Domains
  include Transfer
  include Types

  # AMSF CRM extension - each account has one organization
  has_many :noticed_events, class_name: "Noticed::Event", dependent: :destroy
  has_many :noticed_notifications, class_name: "Noticed::Notification", dependent: :destroy
  has_one :organization, dependent: :destroy
end
