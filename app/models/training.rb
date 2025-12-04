# frozen_string_literal: true

# Training model for tracking AML/CFT staff training sessions.
# Used for AMSF survey elements:
# - a3201 (Was training conducted?)
# - a3202 (Staff trained count)
# - a3203 (Number of sessions)
# - a3204 (Topics covered)
# - a3205 (Training providers used)
# - a3301-a3303 (Training details)
#
class Training < ApplicationRecord
  include AmsfConstants

  # === Associations ===
  belongs_to :organization

  # === Validations ===
  validates :training_date, presence: true
  validates :training_type, presence: true, inclusion: { in: TRAINING_TYPES }
  validates :topic, presence: true, inclusion: { in: TRAINING_TOPICS }
  validates :provider, presence: true, inclusion: { in: TRAINING_PROVIDERS }
  validates :staff_count, presence: true, numericality: { greater_than: 0 }
  validates :duration_hours, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  # === Scopes ===
  scope :for_year, ->(year) {
    where(training_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
  }

  scope :for_organization, ->(org) { where(organization: org) }
  scope :by_type, ->(type) { where(training_type: type) }
  scope :by_topic, ->(topic) { where(topic: topic) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :recent, -> { order(training_date: :desc) }

  # === Instance Methods ===

  def initial?
    training_type == "INITIAL"
  end

  def refresher?
    training_type == "REFRESHER"
  end

  def specialized?
    training_type == "SPECIALIZED"
  end

  def internal?
    provider == "INTERNAL"
  end

  def external?
    provider == "EXTERNAL"
  end

  def amsf_provided?
    provider == "AMSF"
  end

  def online?
    provider == "ONLINE"
  end

  # For display purposes
  def training_type_label
    case training_type
    when "INITIAL" then "Initial Training"
    when "REFRESHER" then "Refresher Training"
    when "SPECIALIZED" then "Specialized Training"
    else training_type
    end
  end

  def topic_label
    case topic
    when "AML_BASICS" then "AML Fundamentals"
    when "PEP_SCREENING" then "PEP Screening"
    when "STR_FILING" then "STR Filing"
    when "RISK_ASSESSMENT" then "Risk Assessment"
    when "SANCTIONS" then "Sanctions"
    when "KYC_PROCEDURES" then "KYC Procedures"
    when "OTHER" then "Other"
    else topic
    end
  end

  def provider_label
    case provider
    when "INTERNAL" then "Internal"
    when "EXTERNAL" then "External Provider"
    when "AMSF" then "AMSF"
    when "ONLINE" then "Online"
    else provider
    end
  end
end
