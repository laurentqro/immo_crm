# frozen_string_literal: true

# Provides organization scoping for API v1 controllers.
# Mirrors OrganizationScoped concern used by web controllers.
module Api
  module V1
    module ApiOrganizationScoped
      extend ActiveSupport::Concern

      included do
        before_action :require_organization
      end

      private

      def current_organization
        @current_organization ||= current_account&.organization
      end

      def current_account
        Current.account
      end

      def require_organization
        return if current_organization.present?

        render json: { error: "No organization found for this account" }, status: :unprocessable_entity
      end

      # Standard JSON error response from a ServiceResult
      def render_service_result(result, status: :ok, created_status: :created)
        if result.success?
          if result.record.is_a?(ActiveRecord::Base)
            render json: serialize_record(result.record), status: created_status
          else
            render json: result.record, status: status
          end
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # Override in controllers for custom serialization
      def serialize_record(record)
        record.as_json
      end
    end
  end
end
