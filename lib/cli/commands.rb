# frozen_string_literal: true

module Cli
  # Command dispatcher for the Immo CLI.
  # Routes subcommands to the appropriate API calls.
  module Commands
    module_function

    def run(args, client:, formatter:)
      resource = args.shift
      action = args.shift

      case resource
      when "clients"    then clients(action, args, client: client, formatter: formatter)
      when "transactions" then transactions(action, args, client: client, formatter: formatter)
      when "str-reports"  then str_reports(action, args, client: client, formatter: formatter)
      when "properties"   then properties(action, args, client: client, formatter: formatter)
      when "trainings"    then trainings(action, args, client: client, formatter: formatter)
      when "submissions"  then submissions(action, args, client: client, formatter: formatter)
      when "compliance"   then compliance(action, args, client: client, formatter: formatter)
      else
        formatter.error("Unknown resource: #{resource}")
        print_help(formatter)
      end
    end

    def clients(action, args, client:, formatter:)
      case action
      when "list"
        params = parse_flags(args)
        data = client.get("/clients", params: params)
        formatter.render(data, columns: %w[id name client_type risk_level is_pep created_at])

      when "show"
        id = args.shift
        data = client.get("/clients/#{id}")
        formatter.render(data)

      when "create"
        body = parse_json_arg(args)
        data = client.post("/clients", body: { client: body })
        formatter.success("Client created (id: #{data['id']})")
        formatter.render(data)

      when "onboard"
        body = parse_json_arg(args)
        data = client.post("/clients/onboard", body: body)
        formatter.success("Client onboarded (id: #{data['id']})")
        formatter.render(data)

      when "assess-risk"
        id = args.shift
        data = client.get("/clients/#{id}/assess_risk")
        formatter.render(data)

      when "update"
        id = args.shift
        body = parse_json_arg(args)
        data = client.patch("/clients/#{id}", body: { client: body })
        formatter.success("Client updated")
        formatter.render(data)

      when "delete"
        id = args.shift
        client.delete("/clients/#{id}")
        formatter.success("Client deleted")

      else
        formatter.error("Usage: immo clients [list|show|create|onboard|assess-risk|update|delete]")
      end
    end

    def transactions(action, args, client:, formatter:)
      case action
      when "list"
        params = parse_flags(args)
        data = client.get("/transactions", params: params)
        formatter.render(data, columns: %w[id transaction_type transaction_date payment_method transaction_value])

      when "show"
        id = args.shift
        data = client.get("/transactions/#{id}")
        formatter.render(data)

      when "create"
        body = parse_json_arg(args)
        data = client.post("/transactions", body: { transaction: body })
        formatter.success("Transaction created (id: #{data['id']})")

      when "screen"
        id = args.shift
        data = client.get("/transactions/#{id}/screen")
        formatter.render(data)

      when "delete"
        id = args.shift
        client.delete("/transactions/#{id}")
        formatter.success("Transaction deleted")

      else
        formatter.error("Usage: immo transactions [list|show|create|screen|delete]")
      end
    end

    def str_reports(action, args, client:, formatter:)
      case action
      when "list"
        params = parse_flags(args)
        data = client.get("/str_reports", params: params)
        formatter.render(data, columns: %w[id reason report_date notes])

      when "show"
        id = args.shift
        data = client.get("/str_reports/#{id}")
        formatter.render(data)

      when "create"
        body = parse_json_arg(args)
        data = client.post("/str_reports", body: { str_report: body })
        formatter.success("STR report created (id: #{data['id']})")

      when "delete"
        id = args.shift
        client.delete("/str_reports/#{id}")
        formatter.success("STR report deleted")

      else
        formatter.error("Usage: immo str-reports [list|show|create|delete]")
      end
    end

    def properties(action, args, client:, formatter:)
      case action
      when "list"
        params = parse_flags(args)
        data = client.get("/managed_properties", params: params)
        formatter.render(data, columns: %w[id property_address property_type management_start_date monthly_rent])

      when "show"
        id = args.shift
        data = client.get("/managed_properties/#{id}")
        formatter.render(data)

      when "create"
        body = parse_json_arg(args)
        data = client.post("/managed_properties", body: { managed_property: body })
        formatter.success("Property created (id: #{data['id']})")

      when "delete"
        id = args.shift
        client.delete("/managed_properties/#{id}")
        formatter.success("Property deleted")

      else
        formatter.error("Usage: immo properties [list|show|create|delete]")
      end
    end

    def trainings(action, args, client:, formatter:)
      case action
      when "list"
        params = parse_flags(args)
        data = client.get("/trainings", params: params)
        formatter.render(data, columns: %w[id training_date training_type topic staff_count])

      when "show"
        id = args.shift
        data = client.get("/trainings/#{id}")
        formatter.render(data)

      when "create"
        body = parse_json_arg(args)
        data = client.post("/trainings", body: { training: body })
        formatter.success("Training created (id: #{data['id']})")

      when "delete"
        id = args.shift
        client.delete("/trainings/#{id}")
        formatter.success("Training deleted")

      else
        formatter.error("Usage: immo trainings [list|show|create|delete]")
      end
    end

    def submissions(action, args, client:, formatter:)
      case action
      when "list"
        data = client.get("/submissions")
        formatter.render(data, columns: %w[id year status taxonomy_version completed_at])

      when "show"
        id = args.shift
        data = client.get("/submissions/#{id}")
        formatter.render(data)

      when "create"
        body = parse_json_arg(args)
        data = client.post("/submissions", body: { submission: body })
        formatter.success("Submission created (id: #{data['id']})")

      when "preview"
        params = parse_flags(args)
        data = client.get("/submissions/preview", params: params)
        formatter.render(data)

      when "validate"
        id = args.shift
        data = client.post("/submissions/#{id}/validate")
        formatter.render(data)

      when "complete"
        id = args.shift
        data = client.post("/submissions/#{id}/complete")
        formatter.success("Submission completed")
        formatter.render(data)

      when "download"
        id = args.shift
        data = client.get("/submissions/#{id}/download")
        # If raw XML, write to file
        filename = "amsf_submission_#{id}.xml"
        File.write(filename, data.is_a?(String) ? data : data.to_json)
        formatter.success("Downloaded to #{filename}")

      else
        formatter.error("Usage: immo submissions [list|show|create|preview|validate|complete|download]")
      end
    end

    def compliance(action, args, client:, formatter:)
      case action
      when "gaps"
        params = parse_flags(args)
        data = client.get("/compliance/gaps", params: params)
        formatter.render(data)

      when "risk-assessment"
        params = parse_flags(args)
        data = client.get("/compliance/risk_assessment", params: params)
        formatter.render(data)

      else
        formatter.error("Usage: immo compliance [gaps|risk-assessment]")
      end
    end

    def parse_flags(args)
      params = {}
      args.each_slice(2) do |key, value|
        next unless key&.start_with?("--")
        params[key.sub(/^--/, "")] = value
      end
      params
    end

    def parse_json_arg(args)
      # Accept --file path or inline JSON
      if args.first == "--file"
        args.shift
        path = args.shift
        JSON.parse(File.read(path))
      elsif args.first&.start_with?("{")
        JSON.parse(args.join(" "))
      else
        parse_flags(args)
      end
    end

    def print_help(formatter)
      formatter.render({
        "resources" => %w[clients transactions str-reports properties trainings submissions compliance],
        "examples" => [
          "immo clients list --risk_level HIGH",
          "immo clients create '{\"name\":\"Dupont\",\"client_type\":\"NATURAL_PERSON\"}'",
          "immo clients onboard --file client.json",
          "immo compliance gaps --year 2025",
          "immo submissions preview --year 2025"
        ]
      })
    end
  end
end
