# frozen_string_literal: true

# CRUD controller for the reporting entity's branches, subsidiaries, and agencies.
class BranchesController < ApplicationController
  include OrganizationScoped

  def index
    authorize Branch
    @branches = policy_scope(Branch).order(:name)
    @branch = current_organization.branches.build
  end

  def create
    @branch = current_organization.branches.build(branch_params)
    authorize @branch

    if @branch.save
      redirect_to branches_path, notice: "Branch added."
    else
      @branches = policy_scope(Branch).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @branch = policy_scope(Branch).find_by(id: params[:id])
    return render_not_found unless @branch

    authorize @branch
    @branch.destroy
    redirect_to branches_path, notice: "Branch removed."
  end

  private

  def branch_params
    params.expect(branch: [:name, :country])
  end
end
