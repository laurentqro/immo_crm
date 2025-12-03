# frozen_string_literal: true

require_relative "model_capability_test_case"

# Tests that our models can provide signatory information.
#
# PRIORITY 1: Always Required
# These fields are mandatory in every AMSF submission regardless of
# activity level or gate question answers.
#
# AMSF Elements:
#   aS1: Signatory name (string) - Who is signing the declaration
#   aS2: Signatory title (string) - Their role/position
#
# Expected Model: Submission
#   - signatory_name: string
#   - signatory_title: string
#
# Run: bin/rails test test/compliance/model_capability/signatory_capability_test.rb
#
class SignatoryCapabilityTest < ModelCapabilityTestCase
  # All Signatory elements (2 total)
  SIGNATORY_ELEMENTS = %w[aS1 aS2].freeze

  # =========================================================================
  # aS1: Signatory Name
  # =========================================================================

  test "aS1: Submission has signatory_name column" do
    assert_model_has_column Submission, :signatory_name,
      "Submission should have signatory_name column for AMSF element aS1"
  end

  test "aS1: signatory_name can store a name" do
    skip "Waiting for signatory_name column" unless Submission.column_names.include?("signatory_name")

    submission = Submission.new(signatory_name: "Jean Dupont")
    assert_equal "Jean Dupont", submission.signatory_name
  end

  # =========================================================================
  # aS2: Signatory Title
  # =========================================================================

  test "aS2: Submission has signatory_title column" do
    assert_model_has_column Submission, :signatory_title,
      "Submission should have signatory_title column for AMSF element aS2"
  end

  test "aS2: signatory_title can store a title" do
    skip "Waiting for signatory_title column" unless Submission.column_names.include?("signatory_title")

    submission = Submission.new(signatory_title: "Directeur Général")
    assert_equal "Directeur Général", submission.signatory_title
  end

  # =========================================================================
  # Integration: Both signatories present
  # =========================================================================

  test "submission can provide complete signatory information" do
    skip "Waiting for signatory columns" unless signatory_columns_exist?

    submission = Submission.new(
      signatory_name: "Marie Martin",
      signatory_title: "Responsable Conformité"
    )

    assert submission.signatory_name.present?, "Should have signatory name"
    assert submission.signatory_title.present?, "Should have signatory title"
  end

  private

  def signatory_columns_exist?
    Submission.column_names.include?("signatory_name") &&
      Submission.column_names.include?("signatory_title")
  end
end
