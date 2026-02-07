# frozen_string_literal: true

require "test_helper"

class TrainingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @training = trainings(:refresher_2025)
  end

  # === Authentication ===

  test "requires authentication for index" do
    get trainings_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "requires authentication for new" do
    get new_training_path
    assert_response :redirect
  end

  test "requires authentication for create" do
    post trainings_path, params: {training: {training_date: Date.current}}
    assert_response :redirect
  end

  test "requires authentication for show" do
    get training_path(@training)
    assert_response :redirect
  end

  test "requires authentication for edit" do
    get edit_training_path(@training)
    assert_response :redirect
  end

  test "requires authentication for update" do
    patch training_path(@training), params: {training: {staff_count: 10}}
    assert_response :redirect
  end

  test "requires authentication for destroy" do
    delete training_path(@training)
    assert_response :redirect
  end

  # === Index ===

  test "index shows trainings for current organization" do
    sign_in @user

    get trainings_path
    assert_response :success
    assert_select "h1", /Training/i
  end

  test "index filters by training_type" do
    sign_in @user

    get trainings_path, params: {training_type: "REFRESHER"}
    assert_response :success
  end

  test "index filters by year" do
    sign_in @user

    get trainings_path, params: {year: 2025}
    assert_response :success
  end

  # === Show ===

  test "show displays training details" do
    sign_in @user

    get training_path(@training)
    assert_response :success
  end

  test "show returns not found for other organization training" do
    sign_in @user
    other_training = trainings(:other_org_training)

    get training_path(other_training)
    assert_response :not_found
  end

  # === New ===

  test "new renders form" do
    sign_in @user

    get new_training_path
    assert_response :success
    assert_select "form"
  end

  # === Create ===

  test "create saves valid training" do
    sign_in @user

    assert_difference("Training.count") do
      post trainings_path, params: {
        training: {
          training_date: Date.current,
          training_type: "INITIAL",
          topic: "AML_BASICS",
          provider: "INTERNAL",
          staff_count: 5,
          duration_hours: 4.0,
          notes: "Test training session"
        }
      }
    end

    assert_redirected_to training_path(Training.last)
    assert_equal "Training was successfully created.", flash[:notice]
  end

  test "create assigns training to current organization" do
    sign_in @user

    post trainings_path, params: {
      training: {
        training_date: Date.current,
        training_type: "REFRESHER",
        topic: "KYC_PROCEDURES",
        provider: "EXTERNAL",
        staff_count: 3
      }
    }

    assert_equal @organization.id, Training.last.organization_id
  end

  test "create renders new on validation error" do
    sign_in @user

    assert_no_difference("Training.count") do
      post trainings_path, params: {
        training: {
          training_date: nil,
          training_type: "INITIAL"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # === Edit ===

  test "edit renders form for training" do
    sign_in @user

    get edit_training_path(@training)
    assert_response :success
    assert_select "form"
  end

  test "edit returns not found for other organization training" do
    sign_in @user
    other_training = trainings(:other_org_training)

    get edit_training_path(other_training)
    assert_response :not_found
  end

  # === Update ===

  test "update saves valid changes" do
    sign_in @user

    patch training_path(@training), params: {
      training: {
        staff_count: 10,
        notes: "Updated notes"
      }
    }

    assert_redirected_to training_path(@training)
    assert_equal "Training was successfully updated.", flash[:notice]
    @training.reload
    assert_equal 10, @training.staff_count
    assert_equal "Updated notes", @training.notes
  end

  test "update renders edit on validation error" do
    sign_in @user

    patch training_path(@training), params: {
      training: {staff_count: 0}
    }

    assert_response :unprocessable_entity
  end

  test "update returns not found for other organization training" do
    sign_in @user
    other_training = trainings(:other_org_training)

    patch training_path(other_training), params: {
      training: {staff_count: 10}
    }

    assert_response :not_found
  end

  # === Destroy ===

  test "destroy deletes training" do
    sign_in @user

    assert_difference("Training.count", -1) do
      delete training_path(@training)
    end

    assert_redirected_to trainings_path
    assert_equal "Training was successfully deleted.", flash[:notice]
  end

  test "destroy returns not found for other organization training" do
    sign_in @user
    other_training = trainings(:other_org_training)

    assert_no_difference("Training.count") do
      delete training_path(other_training)
    end

    assert_response :not_found
  end

  # === Flash Messages ===

  test "shows success message after creating training" do
    sign_in @user

    post trainings_path, params: {
      training: {
        training_date: Date.current,
        training_type: "INITIAL",
        topic: "AML_BASICS",
        provider: "INTERNAL",
        staff_count: 5
      }
    }

    follow_redirect!
    assert_select "#flash", /successfully created/i
  end
end
