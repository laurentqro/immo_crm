# frozen_string_literal: true

class Answer < ApplicationRecord
  belongs_to :submission

  validates :xbrl_id, presence: true
  validates :xbrl_id, uniqueness: { scope: :submission_id }
end
