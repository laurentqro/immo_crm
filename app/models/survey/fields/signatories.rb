# frozen_string_literal: true

class Survey
  module Fields
    module Signatories
      # S1 — aS1: Signatory attestation
      # Type: xbrli:stringItemType — settings-based
      def as1
        setting_value_for("signatory_attestation")
      end

      # S2 — aS2: Authorized representative attestation
      # Type: xbrli:stringItemType — settings-based
      def as2
        setting_value_for("authorized_representative_attestation")
      end

      # S3 — aINCOMPLETE: Incomplete submission reason
      # Type: xbrli:stringItemType — settings-based
      def aincomplete
        setting_value_for("incomplete_submission_reason")
      end
    end
  end
end
