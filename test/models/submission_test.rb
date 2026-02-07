# frozen_string_literal: true

require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @submission = submissions(:draft_submission)
  end

  # === validate_xbrl Tests ===

  test "validate_xbrl returns true when arelle is disabled" do
    with_arelle_disabled do
      assert @submission.validate_xbrl
      assert_empty @submission.errors[:xbrl]
    end
  end

  test "validate_xbrl returns true when validation passes" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: { valid: true, summary: { errors: 0 }, messages: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    with_arelle_enabled do
      assert @submission.validate_xbrl
      assert_empty @submission.errors[:xbrl]
    end
  end

  test "validate_xbrl returns false and adds errors when validation fails" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          summary: { errors: 2 },
          messages: [
            { severity: "error", code: "e1", message: "Error 1" },
            { severity: "error", code: "e2", message: "Error 2" }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    with_arelle_enabled do
      assert_not @submission.validate_xbrl
      assert_includes @submission.errors[:xbrl], "Error 1"
      assert_includes @submission.errors[:xbrl], "Error 2"
    end
  end

  test "validate_xbrl handles connection error gracefully" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_raise(Errno::ECONNREFUSED)

    with_arelle_enabled do
      assert_not @submission.validate_xbrl
      assert @submission.errors[:xbrl].first.include?("temporarily unavailable")
    end
  end

  test "validate_xbrl handles XBRL generation error gracefully" do
    with_arelle_enabled do
      # Use Minitest stub to mock validate_with_arelle raising AmsfSurvey::Error
      mock_survey = Minitest::Mock.new
      mock_survey.expect(:validate_with_arelle, nil) { raise AmsfSurvey::Error, "Invalid data" }

      Survey.stub(:new, mock_survey) do
        assert_not @submission.validate_xbrl
        # Error message from gem is passed through directly
        assert @submission.errors[:xbrl].first.include?("Invalid data")
      end
    end
  end

  # === State Methods ===

  test "draft? returns true for draft status" do
    @submission.status = "draft"
    assert @submission.draft?
  end

  test "draft? returns false for completed status" do
    @submission.status = "completed"
    assert_not @submission.draft?
  end

  test "completed? returns true for completed status" do
    @submission.status = "completed"
    assert @submission.completed?
  end

  test "completed? returns false for draft status" do
    @submission.status = "draft"
    assert_not @submission.completed?
  end

  test "complete! transitions from draft to completed" do
    assert @submission.draft?
    @submission.complete!
    assert @submission.completed?
    assert_not_nil @submission.completed_at
  end

  test "complete! raises error when not in draft status" do
    @submission.update!(status: "completed", completed_at: Time.current)
    assert_raises(Submission::InvalidTransition) do
      @submission.complete!
    end
  end

  # === Validations ===

  test "requires year" do
    submission = Submission.new(organization: @organization)
    assert_not submission.valid?
    assert_includes submission.errors[:year], "can't be blank"
  end

  test "requires organization" do
    submission = Submission.new(year: 2025)
    assert_not submission.valid?
    assert_includes submission.errors[:organization], "must exist"
  end

  test "enforces unique year per organization" do
    Submission.create!(organization: @organization, year: 2099)
    duplicate = Submission.new(organization: @organization, year: 2099)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:year], "has already been taken"
  end
end
