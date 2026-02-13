# frozen_string_literal: true

require "json"
require "fileutils"

module Cli
  # Manages CLI configuration (API URL, token) persisted to ~/.immo.json
  class Config
    CONFIG_PATH = File.expand_path("~/.immo.json")

    def self.load
      return {} unless File.exist?(CONFIG_PATH)
      JSON.parse(File.read(CONFIG_PATH))
    rescue JSON::ParserError
      {}
    end

    def self.save(data)
      FileUtils.mkdir_p(File.dirname(CONFIG_PATH))
      File.write(CONFIG_PATH, JSON.pretty_generate(data))
      File.chmod(0o600, CONFIG_PATH) # Restrict permissions
    end

    def self.get(key)
      load[key]
    end

    def self.set(key, value)
      config = load
      config[key] = value
      save(config)
    end

    def self.configured?
      config = load
      config["url"].to_s.length > 0 && config["token"].to_s.length > 0
    end

    def self.clear
      File.delete(CONFIG_PATH) if File.exist?(CONFIG_PATH)
    end
  end
end
