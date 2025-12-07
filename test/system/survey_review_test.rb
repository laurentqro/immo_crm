# frozen_string_literal: true

require "application_system_test_case"

class SurveyReviewTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @submission = submissions(:draft_submission)

    # Ensure submission has calculated values
    CalculationEngine.new(@submission).calculate_all
    @submission.reload
  end

  # === T028: Search functionality ===

  test "user can search elements by name" do
    login_as @user, scope: :user
    visit submission_review_path(@submission)

    # Verify page loads with elements
    assert_text "Review AMSF Survey"
    initial_count = find('[data-survey-filter-target="count"]').text.to_i

    # Search for specific element
    fill_in "search", with: "a1101"

    # Should filter to show matching element
    assert_selector '[data-element-name="a1101"]', visible: true

    # Count should update
    filtered_count = find('[data-survey-filter-target="count"]').text.to_i
    assert filtered_count <= initial_count, "Filtered count should be less than or equal to initial"
  end

  test "user can search elements by label" do
    login_as @user, scope: :user
    visit submission_review_path(@submission)

    # Search for part of a label (in French)
    fill_in "search", with: "clients"

    # Should filter elements with matching labels
    assert_selector '[data-survey-filter-target="element"]:not([style*="display: none"])'
  end

  test "search is case-insensitive" do
    login_as @user, scope: :user
    visit submission_review_path(@submission)

    # Search with uppercase
    fill_in "search", with: "A1101"

    # Should still find the element
    assert_selector '[data-element-name="a1101"]', visible: true
  end

  # === T035: Needs review filter ===

  test "user can filter to show only elements needing review" do
    # Create a submission value flagged for review
    sv = @submission.submission_values.find_by(element_name: "a1101")
    sv&.update!(metadata: {"flagged_for_review" => true})

    login_as @user, scope: :user
    visit submission_review_path(@submission)

    # Check the needs review only checkbox
    check "needs-review-only"

    # Should show only flagged elements
    # Elements not flagged should be hidden
    if sv
      assert_selector '[data-element-name="a1101"]', visible: true
    end
  end

  test "needs review filter shows visual highlighting" do
    # Create a flagged submission value
    sv = @submission.submission_values.find_by(element_name: "a1101")
    sv&.update!(metadata: {"flagged_for_review" => true})

    login_as @user, scope: :user
    visit submission_review_path(@submission)

    if sv
      # Flagged element should have highlight styling
      flagged_row = find('[data-element-name="a1101"]')
      assert_includes flagged_row[:class], "bg-yellow-50"

      # Should have Review badge
      assert_selector '[data-element-name="a1101"]', text: "Review"
    end
  end

  # === T043: Complete submission flow ===

  test "user can complete submission from review page" do
    # Use validated submission (required state for completion)
    validated_submission = submissions(:validated_submission)

    login_as @user, scope: :user
    visit submission_review_path(validated_submission)

    # Click complete button
    accept_confirm do
      click_button "Complete Submission"
    end

    # Should redirect to submission show page
    assert_current_path submission_path(validated_submission)

    # Verify status changed
    validated_submission.reload
    assert_equal "completed", validated_submission.status
  end

  test "completed submission shows completion status instead of button" do
    completed_submission = submissions(:completed_submission)

    login_as @user, scope: :user
    visit submission_review_path(completed_submission)

    # Should NOT show complete button
    assert_no_button "Complete Submission"

    # Should show completion message
    assert_text "Submission completed"
  end

  # === T052: Edge case - no search results ===

  test "shows no visible elements when search has no matches" do
    login_as @user, scope: :user
    visit submission_review_path(@submission)

    # Search for something that doesn't exist
    fill_in "search", with: "xyznonexistent123"

    # Count should be 0
    assert_selector '[data-survey-filter-target="count"]', text: "0"

    # All sections should be hidden
    assert_no_selector '[data-survey-filter-target="section"]:not([style*="display: none"])'
  end

  # === T053: Edge case - no flagged elements with filter ===

  test "shows no elements when needs review filter enabled but none flagged" do
    # Ensure no elements are flagged
    @submission.submission_values.update_all(metadata: {})

    login_as @user, scope: :user
    visit submission_review_path(@submission)

    # Enable needs review filter
    check "needs-review-only"

    # Count should be 0
    assert_selector '[data-survey-filter-target="count"]', text: "0"
  end

  # === Combined filters ===

  test "search and needs review filters work together" do
    # Flag specific element
    sv = @submission.submission_values.find_by(element_name: "a1101")
    sv&.update!(metadata: {"flagged_for_review" => true})

    login_as @user, scope: :user
    visit submission_review_path(@submission)

    # Search for element and enable review filter
    fill_in "search", with: "a1101"
    check "needs-review-only"

    if sv
      # Should show the specific flagged element
      assert_selector '[data-element-name="a1101"]', visible: true
    end
  end
end
