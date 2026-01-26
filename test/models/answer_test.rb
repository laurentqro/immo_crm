# frozen_string_literal: true

require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  setup do
    @submission = submissions(:draft_submission)
  end

  test "valid with required attributes" do
    answer = Answer.new(
      submission: @submission,
      xbrl_id: "a14001",
      value: "Some explanation"
    )
    assert answer.valid?
  end

  test "requires submission" do
    answer = Answer.new(xbrl_id: "a14001", value: "test")
    assert_not answer.valid?
    assert_includes answer.errors[:submission], "must exist"
  end

  test "requires xbrl_id" do
    answer = Answer.new(submission: @submission, value: "test")
    assert_not answer.valid?
    assert_includes answer.errors[:xbrl_id], "can't be blank"
  end

  test "xbrl_id must be unique per submission" do
    Answer.create!(submission: @submission, xbrl_id: "a14001", value: "first")

    duplicate = Answer.new(submission: @submission, xbrl_id: "a14001", value: "second")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:xbrl_id], "has already been taken"
  end

  test "same xbrl_id allowed for different submissions" do
    other_submission = submissions(:another_submission)
    Answer.create!(submission: @submission, xbrl_id: "a14001", value: "first")

    answer = Answer.new(submission: other_submission, xbrl_id: "a14001", value: "second")
    assert answer.valid?
  end

  test "value can be blank" do
    answer = Answer.new(submission: @submission, xbrl_id: "a14001", value: nil)
    assert answer.valid?
  end
end
