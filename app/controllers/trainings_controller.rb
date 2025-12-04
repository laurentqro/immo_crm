# frozen_string_literal: true

# CRUD controller for Training management.
# Handles AML/CFT staff training records for AMSF reporting.
class TrainingsController < ApplicationController
  include OrganizationScoped

  before_action :set_training, only: [:show, :edit, :update, :destroy]

  def index
    @trainings = policy_scope(Training)
    @trainings = @trainings.by_type(params[:training_type]) if params[:training_type].present?
    @trainings = @trainings.for_year(params[:year].to_i) if params[:year].present?
    @trainings = @trainings.recent
  end

  def show
    authorize @training
  end

  def new
    @training = current_organization.trainings.build
    authorize @training
  end

  def edit
    authorize @training
  end

  def create
    @training = current_organization.trainings.build(training_params)
    authorize @training

    if @training.save
      redirect_to @training, notice: "Training was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @training

    if @training.update(training_params)
      redirect_to @training, notice: "Training was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @training
    @training.destroy
    redirect_to trainings_path, notice: "Training was successfully deleted."
  end

  private

  def set_training
    @training = policy_scope(Training).find_by(id: params[:id])
    render_not_found unless @training
  end

  def training_params
    params.expect(training: policy(@training || Training).permitted_attributes)
  end
end
