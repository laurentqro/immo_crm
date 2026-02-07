# frozen_string_literal: true

module Compliance
  # Identifies compliance gaps in an organization's data.
  # Returns actionable items that need attention.
  #
  # Usage:
  #   result = Compliance::Gaps.call(organization: org)
  #   result.record  # => { gaps: [...], summary: { critical: 2, warning: 3 } }
  #
  class Gaps
    def self.call(organization:, year: Date.current.year)
      new(organization: organization, year: year).call
    end

    def initialize(organization:, year:)
      @organization = organization
      @year = year
    end

    def call
      gaps = []

      gaps.concat(client_gaps)
      gaps.concat(beneficial_owner_gaps)
      gaps.concat(training_gaps)
      gaps.concat(submission_gaps)
      gaps.concat(settings_gaps)

      summary = {
        total: gaps.size,
        critical: gaps.count { |g| g[:severity] == :critical },
        warning: gaps.count { |g| g[:severity] == :warning },
        info: gaps.count { |g| g[:severity] == :info }
      }

      ServiceResult.success({ gaps: gaps, summary: summary })
    end

    private

    def clients
      @clients ||= @organization.clients.kept
    end

    def client_gaps
      gaps = []

      # Clients without risk assessment
      unassessed = clients.where(risk_level: [nil, ""])
      if unassessed.any?
        gaps << {
          severity: :critical,
          category: :clients,
          description: "#{unassessed.count} client(s) without risk assessment",
          client_ids: unassessed.pluck(:id)
        }
      end

      # Clients without due diligence level
      no_dd = clients.where(due_diligence_level: [nil, ""])
      if no_dd.any?
        gaps << {
          severity: :warning,
          category: :clients,
          description: "#{no_dd.count} client(s) without due diligence level set",
          client_ids: no_dd.pluck(:id)
        }
      end

      # PEP clients without enhanced due diligence
      pep_without_edd = clients.peps.where.not(due_diligence_level: "REINFORCED")
      if pep_without_edd.any?
        gaps << {
          severity: :critical,
          category: :clients,
          description: "#{pep_without_edd.count} PEP client(s) without reinforced due diligence",
          client_ids: pep_without_edd.pluck(:id)
        }
      end

      gaps
    end

    def beneficial_owner_gaps
      gaps = []

      # Legal entities/trusts without beneficial owners
      entities_without_owners = clients
        .where(client_type: %w[LEGAL_ENTITY TRUST])
        .left_joins(:beneficial_owners)
        .where(beneficial_owners: { id: nil })

      if entities_without_owners.any?
        gaps << {
          severity: :critical,
          category: :beneficial_owners,
          description: "#{entities_without_owners.count} legal entity/trust client(s) without beneficial owners",
          client_ids: entities_without_owners.pluck(:id)
        }
      end

      gaps
    end

    def training_gaps
      gaps = []

      trainings_this_year = @organization.trainings.for_year(@year)
      if trainings_this_year.empty?
        gaps << {
          severity: :warning,
          category: :training,
          description: "No staff training recorded for #{@year}"
        }
      end

      gaps
    end

    def submission_gaps
      gaps = []

      submission = @organization.submissions.for_year(@year).first
      if submission.nil?
        gaps << {
          severity: :info,
          category: :submissions,
          description: "No AMSF submission created for #{@year}"
        }
      elsif submission.draft?
        gaps << {
          severity: :warning,
          category: :submissions,
          description: "AMSF submission for #{@year} is still in draft status",
          submission_id: submission.id
        }
      end

      gaps
    end

    def settings_gaps
      gaps = []

      required_keys = %w[legal_form staff_total written_aml_policy]
      existing_keys = @organization.settings.where(key: required_keys).pluck(:key)
      missing = required_keys - existing_keys

      if missing.any?
        gaps << {
          severity: :warning,
          category: :settings,
          description: "Missing required organization settings: #{missing.join(', ')}"
        }
      end

      gaps
    end
  end
end
