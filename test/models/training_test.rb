# frozen_string_literal: true

require "test_helper"

class TrainingTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid training with required attributes" do
    training = Training.new(
      organization: @organization,
      training_date: Date.new(2025, 3, 15),
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 5
    )
    assert training.valid?
  end

  test "requires organization" do
    training = Training.new(
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:organization], "must exist"
  end

  test "requires training_date" do
    training = Training.new(
      organization: @organization,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:training_date], "can't be blank"
  end

  test "requires training_type" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:training_type], "can't be blank"
  end

  test "requires topic" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      provider: "EXTERNAL",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:topic], "can't be blank"
  end

  test "requires provider" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:provider], "can't be blank"
  end

  test "requires staff_count" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL"
    )
    assert_not training.valid?
    assert_includes training.errors[:staff_count], "can't be blank"
  end

  # === Training Type Validation ===

  test "training_type must be valid" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "INVALID",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:training_type], "is not included in the list"
  end

  test "accepts all valid training_types" do
    %w[INITIAL REFRESHER SPECIALIZED].each do |type|
      training = Training.new(
        organization: @organization,
        training_date: Date.current,
        training_type: type,
        topic: "AML_BASICS",
        provider: "EXTERNAL",
        staff_count: 5
      )
      assert training.valid?, "Expected training_type '#{type}' to be valid"
    end
  end

  # === Topic Validation ===

  test "topic must be valid" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "INVALID",
      provider: "EXTERNAL",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:topic], "is not included in the list"
  end

  test "accepts all valid topics" do
    %w[AML_BASICS PEP_SCREENING STR_FILING RISK_ASSESSMENT SANCTIONS KYC_PROCEDURES OTHER].each do |topic|
      training = Training.new(
        organization: @organization,
        training_date: Date.current,
        training_type: "REFRESHER",
        topic: topic,
        provider: "EXTERNAL",
        staff_count: 5
      )
      assert training.valid?, "Expected topic '#{topic}' to be valid"
    end
  end

  # === Provider Validation ===

  test "provider must be valid" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "INVALID",
      staff_count: 5
    )
    assert_not training.valid?
    assert_includes training.errors[:provider], "is not included in the list"
  end

  test "accepts all valid providers" do
    %w[INTERNAL EXTERNAL AMSF ONLINE].each do |provider|
      training = Training.new(
        organization: @organization,
        training_date: Date.current,
        training_type: "REFRESHER",
        topic: "AML_BASICS",
        provider: provider,
        staff_count: 5
      )
      assert training.valid?, "Expected provider '#{provider}' to be valid"
    end
  end

  # === Numeric Validations ===

  test "staff_count must be greater than 0" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 0
    )
    assert_not training.valid?
    assert_includes training.errors[:staff_count], "must be greater than 0"
  end

  test "staff_count must be positive" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: -1
    )
    assert_not training.valid?
    assert_includes training.errors[:staff_count], "must be greater than 0"
  end

  test "duration_hours must be non-negative when present" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 5,
      duration_hours: -1
    )
    assert_not training.valid?
    assert_includes training.errors[:duration_hours], "must be greater than or equal to 0"
  end

  test "duration_hours can be blank" do
    training = Training.new(
      organization: @organization,
      training_date: Date.current,
      training_type: "REFRESHER",
      topic: "AML_BASICS",
      provider: "EXTERNAL",
      staff_count: 5,
      duration_hours: nil
    )
    assert training.valid?
  end

  # === Scopes ===

  test "for_year scope filters by year" do
    training_2025 = trainings(:refresher_2025)
    training_2024 = trainings(:initial_2024)

    trainings_2025 = Training.for_year(2025)
    assert_includes trainings_2025, training_2025
    assert_not_includes trainings_2025, training_2024
  end

  test "for_organization scope filters by organization" do
    org_one_training = trainings(:refresher_2025)
    org_two_training = trainings(:other_org_training)

    org_one_trainings = Training.for_organization(@organization)
    assert_includes org_one_trainings, org_one_training
    assert_not_includes org_one_trainings, org_two_training
  end

  test "by_type scope filters by training_type" do
    refresher = trainings(:refresher_2025)
    initial = trainings(:initial_2024)

    refreshers = Training.by_type("REFRESHER")
    assert_includes refreshers, refresher
    assert_not_includes refreshers, initial
  end

  # === Associations ===

  test "belongs to organization" do
    training = trainings(:refresher_2025)
    assert_equal @organization, training.organization
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert Training.include?(AmsfConstants)
  end
end
