# frozen_string_literal: true

module Api
  module V1
    class ComplianceController < Api::BaseController
      include ApiOrganizationScoped

      # GET /api/v1/compliance/gaps
      def gaps
        year = params[:year]&.to_i || Date.current.year
        result = Compliance::Gaps.call(organization: current_organization, year: year)
        render json: result.record
      end

      # GET /api/v1/compliance/risk_assessment
      def risk_assessment
        year = params[:year]&.to_i || Date.current.year
        result = Compliance::RiskAssessment.call(organization: current_organization, year: year)
        render json: result.record
      end
    end
  end
end
