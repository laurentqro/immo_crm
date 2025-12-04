# frozen_string_literal: true

# CRUD controller for ManagedProperty management.
# Handles property management contracts (gestion locative).
class ManagedPropertiesController < ApplicationController
  include OrganizationScoped

  before_action :set_managed_property, only: [:show, :edit, :update, :destroy]

  def index
    @managed_properties = policy_scope(ManagedProperty).includes(:client)
    @managed_properties = @managed_properties.where(property_type: params[:property_type]) if params[:property_type].present?

    if params[:status] == "active"
      @managed_properties = @managed_properties.active
    elsif params[:status] == "ended"
      @managed_properties = @managed_properties.ended
    end

    @managed_properties = @managed_properties.order(management_start_date: :desc)
  end

  def show
    authorize @managed_property
  end

  def new
    @managed_property = current_organization.managed_properties.build
    authorize @managed_property
  end

  def edit
    authorize @managed_property
  end

  def create
    @managed_property = current_organization.managed_properties.build(managed_property_params)
    authorize @managed_property

    if @managed_property.save
      redirect_to @managed_property, notice: "Managed property was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @managed_property

    if @managed_property.update(managed_property_params)
      redirect_to @managed_property, notice: "Managed property was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @managed_property
    @managed_property.destroy
    redirect_to managed_properties_path, notice: "Managed property was successfully deleted."
  end

  private

  def set_managed_property
    @managed_property = policy_scope(ManagedProperty).includes(:client).find_by(id: params[:id])
    render_not_found unless @managed_property
  end

  def managed_property_params
    params.expect(managed_property: policy(@managed_property || ManagedProperty).permitted_attributes)
  end
end
