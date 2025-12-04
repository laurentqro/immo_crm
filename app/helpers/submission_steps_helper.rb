# frozen_string_literal: true

# Helper methods for submission steps wizard views
module SubmissionStepsHelper
  STEP_NAMES = {
    1 => "Review",
    2 => "Policies",
    3 => "Questions",
    4 => "Properties",
    5 => "Revenue",
    6 => "Training",
    7 => "Validate"
  }.freeze

  def step_name(step_num)
    STEP_NAMES[step_num] || "Step #{step_num}"
  end
end
