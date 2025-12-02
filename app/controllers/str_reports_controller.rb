# frozen_string_literal: true

# CRUD controller for STR Report (Suspicious Transaction Report) management.
# Handles AML/CFT compliance reporting for suspicious activities.
class StrReportsController < ApplicationController
  include OrganizationScoped

  before_action :set_str_report, only: [:show, :edit, :update, :destroy]

  def index
    @str_reports = policy_scope(StrReport).includes(:client, :linked_transaction)

    # Apply filters
    @str_reports = @str_reports.for_year(params[:year].to_i) if params[:year].present?
    @str_reports = @str_reports.by_reason(params[:reason]) if params[:reason].present?

    @str_reports = @str_reports.recent

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    authorize @str_report
  end

  def new
    @str_report = current_organization.str_reports.build
    @str_report.client_id = params[:client_id] if params[:client_id].present?
    @str_report.transaction_id = params[:transaction_id] if params[:transaction_id].present?
    authorize @str_report
  end

  def edit
    authorize @str_report
  end

  def create
    @str_report = current_organization.str_reports.build(str_report_params)
    authorize @str_report

    respond_to do |format|
      if @str_report.save
        format.html { redirect_to @str_report, notice: "STR report was successfully created." }
        format.turbo_stream { flash.now[:notice] = "STR report was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @str_report

    respond_to do |format|
      if @str_report.update(str_report_params)
        format.html { redirect_to @str_report, notice: "STR report was successfully updated." }
        format.turbo_stream { flash.now[:notice] = "STR report was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @str_report
    @str_report.discard

    respond_to do |format|
      format.html { redirect_to str_reports_path, notice: "STR report was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "STR report was successfully deleted." }
    end
  end

  private

  def set_str_report
    @str_report = policy_scope(StrReport.with_discarded).find_by(id: params[:id])
    render_not_found unless @str_report
  end

  def str_report_params
    params.expect(str_report: policy(@str_report || StrReport).permitted_attributes)
  end
end
