# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Cli
  # HTTP client for the Immo CRM API.
  # Handles authentication, JSON serialization, and error handling.
  class ApiClient
    class ApiError < StandardError
      attr_reader :status, :body

      def initialize(status, body)
        @status = status
        @body = body
        super("HTTP #{status}: #{body}")
      end
    end

    def initialize(base_url:, token:)
      @base_url = base_url.chomp("/")
      @token = token
    end

    def get(path, params: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Get.new(uri)
      execute(uri, request)
    end

    def post(path, body: {})
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      request.body = body.to_json
      execute(uri, request)
    end

    def patch(path, body: {})
      uri = build_uri(path)
      request = Net::HTTP::Patch.new(uri)
      request.body = body.to_json
      execute(uri, request)
    end

    def delete(path)
      uri = build_uri(path)
      request = Net::HTTP::Delete.new(uri)
      execute(uri, request)
    end

    private

    def build_uri(path, params = {})
      uri = URI("#{@base_url}/api/v1#{path}")
      uri.query = URI.encode_www_form(params) if params.any?
      uri
    end

    def execute(uri, request)
      request["Authorization"] = "token #{@token}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 10
      http.read_timeout = 30

      response = http.request(request)

      case response.code.to_i
      when 200..299
        return nil if response.body.nil? || response.body.empty?
        JSON.parse(response.body)
      else
        raise ApiError.new(response.code.to_i, response.body)
      end
    end
  end
end
