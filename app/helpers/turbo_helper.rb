# frozen_string_literal: true

# Helper for consistent Turbo Frame naming conventions across the CRM.
# Provides standard patterns for frame IDs and target names.
module TurboHelper
  # Generate a Turbo Frame ID for a model record
  # Usage: frame_id(@client) => "client_123"
  def frame_id(record)
    dom_id(record)
  end

  # Generate a Turbo Frame ID for a new record form
  # Usage: new_frame_id(Client) => "new_client"
  def new_frame_id(model_class)
    "new_#{model_class.model_name.singular}"
  end

  # Generate a Turbo Frame ID for an edit form
  # Usage: edit_frame_id(@client) => "edit_client_123"
  def edit_frame_id(record)
    "edit_#{dom_id(record)}"
  end

  # Generate a Turbo Frame ID for a list/index
  # Usage: list_frame_id(Client) => "clients_list"
  def list_frame_id(model_class)
    "#{model_class.model_name.plural}_list"
  end

  # Generate a Turbo Frame ID for a section of a record
  # Usage: section_frame_id(@client, :beneficial_owners) => "client_123_beneficial_owners"
  def section_frame_id(record, section)
    "#{dom_id(record)}_#{section}"
  end

  # Generate a Turbo Frame ID for a modal
  # Usage: modal_frame_id(:confirm_delete) => "modal_confirm_delete"
  def modal_frame_id(name)
    "modal_#{name}"
  end

  # Generate a Turbo Frame ID for wizard steps
  # Usage: wizard_step_frame_id(:submission, 2) => "submission_step_2"
  def wizard_step_frame_id(wizard_name, step)
    "#{wizard_name}_step_#{step}"
  end
end
