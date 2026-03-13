# frozen_string_literal: true

module Api
  module V1
    class StrReportsController < Api::BaseController
      include ApiOrganizationScoped

      before_action :set_str_report, only: [:show, :update, :destroy]

      # GET /api/v1/str_reports
      def index
        reports = policy_scope(StrReport).includes(:client, :linked_transaction)
        reports = reports.for_year(params[:year].to_i) if params[:year].present?
        reports = reports.by_reason(params[:reason]) if params[:reason].present?
        reports = reports.recent

        render json: reports.as_json(include: {
          client: { only: [:id, :name] },
          linked_transaction: { only: [:id, :transaction_type, :transaction_date] }
        })
      end

      # GET /api/v1/str_reports/:id
      def show
        authorize @str_report
        render json: @str_report.as_json(include: {
          client: { only: [:id, :name] },
          linked_transaction: { only: [:id, :transaction_type, :transaction_date] }
        })
      end

      # POST /api/v1/str_reports
      def create
        report = current_organization.str_reports.build(str_report_params)
        authorize report

        if report.save
          render json: report.as_json, status: :created
        else
          render json: { errors: report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/str_reports/:id
      def update
        authorize @str_report

        if @str_report.update(str_report_params)
          render json: @str_report.as_json
        else
          render json: { errors: @str_report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/str_reports/:id
      def destroy
        authorize @str_report
        @str_report.discard
        head :no_content
      end

      private

      def set_str_report
        @str_report = policy_scope(StrReport.with_discarded).find_by(id: params[:id])
        render json: { error: "STR report not found" }, status: :not_found unless @str_report
      end

      def str_report_params
        params.require(:str_report).permit(
          StrReportPolicy.new(pundit_user, StrReport).permitted_attributes
        )
      end
    end
  end
end
