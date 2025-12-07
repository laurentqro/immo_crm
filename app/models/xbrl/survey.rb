# frozen_string_literal: true

module Xbrl
  # Survey defines the AMSF questionnaire structure (sections and element assignments).
  # The structure is defined here because it does not exist in the XBRL taxonomy files -
  # the taxonomy only contains element definitions, not how they're grouped in the questionnaire.
  #
  # This module provides:
  # - SECTIONS constant with section_id => { title:, elements: [] } mapping
  # - sections: Returns all sections in display order
  # - elements_for: Returns element names for a specific section
  # - validate!: Boot-time validation to ensure all referenced elements exist in taxonomy
  #
  # Section IDs follow the official AMSF questionnaire numbering:
  # - Tab 1 (Customer Risk): "1.1" through "1.12"
  # - Tab 2 (Products & Services Risk): "2.1" through "2.10"
  # - Tab 3 (Distribution Risk): "3.1" through "3.7"
  # - Tab 4 (Controls): "C1.1" through "C1.15" (prefixed with C to distinguish from Tab 1)
  # - Tab 5 (Signatories): "S1"
  #
  module Survey
    # Section structure matching official AMSF questionnaire.
    # Format: { section_id => { title:, elements: [] } }
    # Elements are taxonomy element names in presentation order.
    SECTIONS = {
      # === Tab 1: Customer Risk ===
      "1.1" => {
        title: "Active in Reporting Cycle",
        elements: %w[aACTIVE aACTIVEPS aACTIVERENTALS]
      },
      "1.2" => {
        title: "Clients Summary",
        elements: %w[a1101 a1102 a1103 a1104 a1105B a1106B a1106BRENTALS a1105W a1106W]
      },
      "1.3" => {
        title: "Beneficial Owners",
        elements: %w[a1204S a1204O a1203D a1203 a1202O a1202OB a120425O a1207O a1210O a1204S1]
      },
      "1.4" => {
        title: "Distinguishing Client Types",
        elements: %w[a11201BCD a11201BCDU a1801 a13601]
      },
      "1.5" => {
        title: "Clients - Natural Persons",
        elements: %w[a1401R a1401 a1402 a1403B a1404B a1403R aIR129 aIR1210 aIR233 aIR233B aIR233S
          aIR235B_1 aIR235B_2 aIR235S aIR117 aIR237B aIR238B aIR239B]
      },
      "1.6" => {
        title: "Clients - Legal Persons",
        elements: %w[a1501 a1502B a1503B a155 a11206B a112012B]
      },
      "1.7" => {
        title: "Clients - Trusts and Other Legal Arrangements",
        elements: %w[a1802BTOLA a1802TOLA a1807ATOLA a11001BTOLA a1806TOLA a1807TOLA a11006
          a1808 a1809 a3208TOLA a3212CTOLA]
      },
      "1.8" => {
        title: "PEPs",
        elements: %w[a11301 a11302RES a11302 a11304B a11305B a11307 a11309B]
      },
      "1.9" => {
        title: "Virtual Asset Service Providers",
        elements: %w[a13501B a13601A a13601CW a13603BB a13604BB a13601B a13601EP a13603AB
          a13604AB a13601C a13601ICO a13603CACB a13604CB a13601C2 a13601OTHER
          a13603DB a13604DB a13604E a13602B a13602A a13602C a13602D]
      },
      "1.10" => {
        title: "2nd Nationalities",
        elements: %w[a1402]
      },
      "1.11" => {
        title: "Monegasque Client Types - Purchases and Sales",
        elements: %w[aC171 a11502B a11602B a11702B a11802B a12002B a12102B a12202B a12302B
          a12302C a12402B a12502B a12602B a12702B a12802B a12902B a13002B a13202B
          a13302B a13402B a13702B a13802B a13902B a14102B a14202B a14302B a14402B
          a14502B a14602B a14702B aMLES]
      },
      "1.12" => {
        title: "Comments & Feedback",
        elements: %w[a14801 a14001]
      },

      # === Tab 2: Products & Services Risk ===
      "2.1" => {
        title: "Payment Types with Clients - Cheques",
        elements: %w[a2101W a2101WRP a2102W a2102BW]
      },
      "2.2" => {
        title: "Payment Types by Clients - Cheques",
        elements: %w[a2101B a2102B a2102BB]
      },
      "2.3" => {
        title: "Payment Types with Clients - Electronic Transfers",
        elements: %w[a2104W a2104WRP a2105W]
      },
      "2.4" => {
        title: "Payment Types by Clients - Electronic Transfers",
        elements: []
      },
      "2.5" => {
        title: "Payment Types with Clients - Cash",
        elements: []
      },
      "2.6" => {
        title: "Payment Types by Clients - Cash",
        elements: []
      },
      "2.7" => {
        title: "Virtual Currencies",
        elements: %w[a2201A a2201D a2202 a2203]
      },
      "2.8" => {
        title: "Services Offered, Agent for Purchases & Sales",
        elements: %w[aIR2391 aIR2392 aIR2393]
      },
      "2.9" => {
        title: "Services Offered, Agent for Rentals",
        elements: %w[aIR234 aIR236 aIR2313 aIR2316]
      },
      "2.10" => {
        title: "Comments & Feedback",
        elements: %w[a2501A a2501]
      },

      # === Tab 3: Distribution Risk ===
      "3.1" => {
        title: "Identification",
        elements: %w[a3101 a3102 a3103 a3104 a3105]
      },
      "3.2" => {
        title: "Onboarding",
        elements: %w[aB3206 aB3207 a3209 a3210C a3211C a3201 a3202 a3203 a3204 a3205]
      },
      "3.3" => {
        title: "Structure",
        elements: %w[aIR33LF a3301 aIR328 a3302 a3303 a3304C a3304 a3305 a3306 a3306A a3306B
          a3307 a3308 a3210B a3211B a3210 a3211]
      },
      "3.4" => {
        title: "Entity Finances",
        elements: %w[a381 a3802 a3803 a3804]
      },
      "3.5" => {
        title: "Rejected Relationships",
        elements: %w[a3401 a3402 a3403]
      },
      "3.6" => {
        title: "Terminated Relationships",
        elements: %w[a3414 a3415 a3416]
      },
      "3.7" => {
        title: "Comments & Feedback",
        elements: %w[a3701A a3701]
      },

      # === Tab 4: Controls ===
      "C1.1" => {
        title: "Structure",
        elements: %w[aC1102A aC1102 aC1101Z aC114 aC1106 aC1518A]
      },
      "C1.2" => {
        title: "Policies & Procedures",
        elements: %w[aC1201 aC1202 aC1203 aC1204 aC1205 aC1206 aC1207 aC1209B aC1209C aC1208 aC1209]
      },
      "C1.3" => {
        title: "Governance",
        elements: %w[aC1301 aC1302 aC1303 aC1304]
      },
      "C1.4" => {
        title: "Compliance & Violations",
        elements: %w[aC1401 aC1402 aC1403]
      },
      "C1.5" => {
        title: "Training",
        elements: %w[aC1501 aC1503B aC1506]
      },
      "C1.6" => {
        title: "CDD",
        elements: %w[aC1625 aC1626 aC1627 aC168 aC1629 aC1630 aC1601 aC1602 aC1631 aC1633
          aC1634 aC1635 aC1636 aC1637 aC1608 aC1635A aC1638A aC1639A aC1641A
          aC1640A aC1642A aC1609 aC1610 aC1611 aC1612A aC1612 aC1614 aC1615
          aC1622F aC1622A aC1622B aC1620 aC1617 aC1616B aC1616A aC1618 aC1619
          aC1616C aC1621]
      },
      "C1.7" => {
        title: "EDD",
        elements: %w[aC1701 aC1702 aC1703]
      },
      "C1.8" => {
        title: "Risk Assessments",
        elements: %w[aB1801B aC1801 aC1802 aC1806 aC1807 aC1811 aC1812 aC1813 aC1814W]
      },
      "C1.9" => {
        title: "Audit / Controls",
        elements: %w[aC1904]
      },
      "C1.10" => {
        title: "Record Keeping",
        elements: %w[aC11101 aC11102 aC11103 aC11104 aC11105]
      },
      "C1.11" => {
        title: "Targeted Financial Sanctions (TFS)",
        elements: %w[aC11201 aC1125A aC12333 aC12236 aC12237]
      },
      "C1.12" => {
        title: "PEPs",
        elements: %w[aC11301 aC11302 aC11303 aC11304 aC11305 aC11306 aC11307]
      },
      "C1.13" => {
        title: "Cash Transactions",
        elements: %w[aC11401 aC11402 aC11403]
      },
      "C1.14" => {
        title: "Suspicious Transaction Reporting",
        elements: %w[aC11501B aC11502 aC11504 aC11508]
      },
      "C1.15" => {
        title: "Comments & Feedback",
        elements: %w[aC116A aC11601]
      },

      # === Tab 5: Signatories ===
      "S1" => {
        title: "Attestation",
        elements: %w[aS1 aS2 aINCOMPLETE]
      }
    }.freeze

    class << self
      # Returns all sections in display order.
      # @return [Array<Hash>] Array of { id:, title:, elements: }
      def sections
        @sections ||= SECTIONS.map do |id, data|
          {id: id, title: data[:title], elements: data[:elements]}
        end.sort_by { |s| section_sort_key(s[:id]) }.freeze
      end

      # Returns element names for a specific section.
      # @param section_id [String] Section identifier (e.g., "1.1", "C1.2")
      # @return [Array<String>] Element names
      def elements_for(section_id)
        SECTIONS.dig(section_id, :elements) || []
      end

      # Returns a section by ID.
      # @param section_id [String] Section identifier (e.g., "1.1")
      # @return [Hash, nil] Section hash with :id, :title, :elements or nil
      def section(section_id)
        data = SECTIONS[section_id]
        return nil unless data

        {id: section_id, title: data[:title], elements: data[:elements]}
      end

      # Returns the section containing a specific element.
      # @param element_name [String] Element name (e.g., "a1101")
      # @return [Hash, nil] Section hash or nil if not found
      def section_for_element(element_name)
        SECTIONS.each do |id, data|
          return {id: id, title: data[:title], elements: data[:elements]} if data[:elements].include?(element_name)
        end
        nil
      end

      # Returns a flat array of all element names across all sections.
      # @return [Array<String>] All element names
      def all_element_names
        @all_element_names ||= SECTIONS.values.flat_map { |data| data[:elements] }.freeze
      end

      # Validates all element names exist in taxonomy.
      # Called at boot time via initializer.
      # @raise [RuntimeError] If any element name is invalid
      def validate!
        return unless Taxonomy.loaded?

        invalid_elements = []
        all_element_names.each do |element_name|
          invalid_elements << element_name unless Taxonomy.element(element_name)
        end

        if invalid_elements.any?
          Rails.logger.warn(
            "Xbrl::Survey references #{invalid_elements.size} elements not in taxonomy: " \
            "#{invalid_elements.first(10).join(", ")}#{(invalid_elements.size > 10) ? "..." : ""}"
          )
        end

        true
      end

      # Clears memoized data (for testing/development)
      def reload!
        @sections = nil
        @all_element_names = nil
      end

      private

      # Generate sort key for section ordering.
      # Sections are sorted: 1.x < 2.x < 3.x < C1.x < S1
      def section_sort_key(section_id)
        case section_id
        when /^(\d+)\.(\d+)$/
          # Numeric sections: "1.1" -> [0, 1, 1]
          [0, Regexp.last_match(1).to_i, Regexp.last_match(2).to_i]
        when /^C(\d+)\.(\d+)$/
          # Controls sections: "C1.1" -> [1, 1, 1]
          [1, Regexp.last_match(1).to_i, Regexp.last_match(2).to_i]
        when /^S(\d+)$/
          # Signatories: "S1" -> [2, 1, 0]
          [2, Regexp.last_match(1).to_i, 0]
        else
          [99, 0, 0]
        end
      end
    end
  end
end
