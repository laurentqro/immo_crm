# Gems cannot be loaded here since this runs during bundler/setup

module Jumpstart
  def self.config = @config ||= Configuration.load!

  def self.config=(value)
    @config = value
  end

  module YAMLSerializer
    # A simple YAML serializer that does not support nested elements

    module_function

    def load(path)
      result = {}
      key = nil
      multiline = false

      File.readlines(path, chomp: true).each do |line|
        # multiline hash key
        if (match = /^(\w+):\s*\|-/.match(line))
          multiline = true
          key = match[1]
          result[key] = ""

        # hash keys
        elsif (match = /^(\w+):\s*(.*)/.match(line))
          multiline = false
          key, value = match[1], match[2]
          result[key] = value unless value.empty?

        # array entries
        elsif line.start_with? "- "
          result[key] ||= []
          result[key] << line.delete_prefix("- ")

        # multiline string
        elsif multiline
          result[key] += "\n" unless result[key].empty?
          result[key] += line.strip
        end
      end

      result
    end

    def dump(object)
      yaml = "---\n"
      object.instance_variables.each do |ivar|
        key = ivar.to_s.delete_prefix("@")
        value = object.instance_variable_get(ivar)
        yaml << key << ":"

        if value.is_a?(Array)
          yaml << value.map { |e| "\n- #{e.to_s.gsub(/\s+/, " ")}" }.join << "\n"
        elsif value.is_a?(String) && value.include?("\n")
          yaml << " |-\n  " << value.split("\n").join("\n  ") << "\n"
        else
          yaml << " " << value.to_s.gsub(/\s+/, " ") << "\n"
        end
      end

      yaml
    end

    def dump_to_file(path, object)
      File.write(path, dump(object))
    end
  end

  class Configuration
    QUEUE_ADAPTERS = {
      "I'll configure my own" => nil,
      "Async" => :async,
      "SolidQueue" => :solid_queue,
      "Sidekiq" => :sidekiq
    }.freeze

    def job_command(processor)
      case processor.to_s
      when "solid_queue"
        "bin/jobs"
      when "sidekiq"
        "bundle exec sidekiq"
      end
    end

    # Manages 3rd party service integrations
    module Integratable
      INTEGRATIONS = {
        "AirBrake" => "airbrake",
        "AppSignal" => "appsignal",
        "BugSnag" => "bugsnag",
        "Honeybadger" => "honeybadger",
        "Intercom" => "intercom",
        "Rollbar" => "rollbar",
        "Scout" => "scout",
        "Sentry" => "sentry",
        "Skylight" => "skylight"
      }.freeze

      attr_writer :integrations

      INTEGRATIONS.values.each do |provider|
        define_method(:"#{provider}?") do
          integrations.include?(provider)
        end
      end

      def integrations = @integrations || []

      def self.has_credentials?(integration)
        credentials_for(integration).first.last.present? if credentials_for(integration).present?
      end

      def self.credentials_for(integration)
        Rails.application.credentials.dig(Rails.env, integration.to_sym) || Rails.application.credentials.dig(integration.to_sym) || {}
      end
    end

    MAIL_PROVIDERS = {
      "Amazon SES" => :ses,
      "Mailgun" => :mailgun,
      "Mailjet" => :mailjet,
      "Mailpace" => :mailpace,
      "Postmark" => :postmark,
      "Resend" => :resend,
      "Sendgrid" => :sendgrid
    }.freeze

    module Mailer
      def smtp_settings
        case email_provider
        when "mailjet"
          {
            address: "in.mailjet.com",
            user_name: get_credential(:mailjet, :username),
            password: get_credential(:mailjet, :password)
          }.merge(shared_smtp_settings)
        when "sendgrid"
          {
            address: "smtp.sendgrid.net",
            domain: get_credential(:sendgrid, :domain),
            user_name: get_credential(:sendgrid, :username),
            password: get_credential(:sendgrid, :password)
          }.merge(shared_smtp_settings)
        when "ses"
          {
            address: get_credential(:ses, :address),
            user_name: get_credential(:ses, :username),
            password: get_credential(:ses, :password)
          }.merge(shared_smtp_settings)
        else
          {}
        end
      end

      def shared_smtp_settings
        {
          port: 587,
          authentication: :plain,
          enable_starttls_auto: true,
          domain: domain
        }
      end
    end

    module Payable
      attr_writer :payment_processors

      def payment_processors = Array(@payment_processors)

      def payments_enabled? = payment_processors.any?

      def stripe? = payment_processors.include? "stripe"

      def lemon_squeezy? = payment_processors.include? "lemon_squeezy"

      def braintree? = payment_processors.include? "braintree"

      def paypal? = payment_processors.include? "paypal"

      def paddle_billing? = payment_processors.include? "paddle_billing"

      def paddle_classic? = payment_processors.include? "paddle_classic"
    end

    include Integratable
    include Mailer
    include Payable

    # Attributes
    attr_accessor :application_name
    attr_accessor :business_name
    attr_accessor :business_address
    attr_accessor :domain
    attr_accessor :background_job_processor
    attr_accessor :email_provider
    attr_accessor :default_from_email
    attr_accessor :support_email
    attr_accessor :multitenancy
    attr_accessor :apns
    attr_accessor :fcm
    attr_accessor :account_types
    attr_writer :gems
    attr_writer :omniauth_providers

    def self.load!
      if File.exist?(config_path)
        new(YAMLSerializer.load(config_path)).apply_upgrades
      else
        new
      end
    end

    def self.config_path = File.join("config", "jumpstart.yml")

    def self.create_default_config
      FileUtils.cp File.join(File.dirname(__FILE__), "../templates/jumpstart.yml"), config_path
    end

    def initialize(options = {})
      @application_name = options["application_name"] || "My App"
      @business_name = options["business_name"] || "My Company, LLC"
      @business_address = options["business_address"] || ""
      @domain = options["domain"] || "example.com"
      @support_email = options["support_email"] || "support@example.com"
      @default_from_email = options["default_from_email"] || "My App <no-reply@example.com>"
      @background_job_processor = QUEUE_ADAPTERS.values.map(&:to_s).include?(options["background_job_processor"]) ? options["background_job_processor"] : nil
      @email_provider = options["email_provider"]
      @account_types = options["account_types"] || (cast_to_boolean(options["personal_accounts"], default: true) ? "both" : "team")
      @apns = cast_to_boolean(options["apns"])
      @fcm = cast_to_boolean(options["fcm"])
      @integrations = options.fetch("integrations", [])
      @omniauth_providers = options.fetch("omniauth_providers", [])
      @payment_processors = options.fetch("payment_processors", [])
      @multitenancy = options.fetch("multitenancy", [])
      @gems = options.fetch("gems", [])
    end

    def apply_upgrades
      if @payment_processors&.include? "paddle"
        @payment_processors.delete "paddle"
        @payment_processors << "paddle_classic"
        write_config
      end
      if @email_provider == "ohmysmtp"
        @email_provider = "mailpace"
        write_config
      end
      self
    end

    def write_config
      YAMLSerializer.dump_to_file(self.class.config_path, self)
    end

    def save
      write_config
      update_procfiles
      copy_configs

      # Change the Jumpstart config to the latest version
      Jumpstart.config = self
    end

    def job_processor = background_job_processor&.to_sym

    def queue_adapter = job_processor

    def gems = Array(@gems)

    def omniauth_providers = Array(@omniauth_providers)

    def register_with_account? = !personal_accounts?

    def personal_accounts?
      ["both", "personal"].include? account_types
    end

    def team_accounts?
      ["both", "team"].include? account_types
    end

    def personal_accounts_only?
      account_types == "personal"
    end

    def team_accounts_only?
      account_types == "team"
    end

    def apns? = cast_to_boolean(@apns || false)

    def fcm? = cast_to_boolean(@fcm || false)

    def update_procfiles
      write_procfile Rails.root.join("Procfile"), procfile_content
      write_procfile Rails.root.join("Procfile.dev"), procfile_content(dev: true)
    end

    def copy_configs
      if queue_adapter == :sidekiq
        copy_template("config/sidekiq.yml")
      end

      if airbrake?
        copy_template("config/initializers/airbrake.rb")
      end

      if appsignal?
        copy_template("config/appsignal.yml")
      end

      if bugsnag?
        copy_template("config/initializers/bugsnag.rb")
      end

      if honeybadger?
        copy_template("config/honeybadger.yml")
      end

      if intercom?
        copy_template("config/initializers/intercom.rb")
      end

      if rollbar?
        copy_template("config/initializers/rollbar.rb")
      end

      if scout?
        copy_template("config/scout_apm.yml")
      end

      if sentry?
        copy_template("config/initializers/sentry.rb")
      end

      if skylight?
        copy_template("config/skylight.yml")
      end
    end

    def model_name = ActiveModel::Name.new(self, nil, "Configuration")

    def persisted? = false

    private

    # Search through credentials env scoped, then unscoped
    def get_credential(*)
      Rails.application.credentials.dig(Rails.env.to_sym, *) || Rails.application.credentials.dig(*)
    end

    def procfile_content(dev: false)
      content = {web: "bundle exec rails s"}

      # Background workers
      if (worker_command = job_command(queue_adapter))
        content[:worker] = worker_command
      end

      # Add the Stripe CLI
      content[:stripe] = "stripe listen --forward-to localhost:3000/webhooks/stripe" if dev && stripe?

      content
    end

    def write_procfile(path, commands)
      commands.each do |name, command|
        new_line = "#{name}: #{command}"

        if (matches = File.foreach(path).grep(/#{name}:/)) && matches.any?
          # Warn only if lines don't match
          if (old_line = matches.first.chomp) && old_line != new_line
            Rails.logger.warn "\n'#{name}' already exists in #{path}, skipping. \nOld: `#{old_line}`\nNew: `#{new_line}`\n"
          end
        else
          File.open(path, "a") { |f| f.write("#{name}: #{command}\n") }
        end
      end
    end

    # Safely copy template, so we don't blow away any customizations you made
    def copy_template(filename)
      unless File.exist?(filename)
        FileUtils.cp(template_path(filename), Rails.root.join(filename))
      end
    end

    def template_path(filename) = Rails.root.join("lib/templates", filename)

    FALSE_VALUES = [
      false, 0,
      "0", :"0",
      "f", :f,
      "F", :F,
      "false", # :false,
      "FALSE", :FALSE,
      "off", :off,
      "OFF", :OFF
    ].freeze

    def cast_to_boolean(value, default: nil)
      if value.nil? || value == ""
        default
      else
        !FALSE_VALUES.include?(value)
      end
    end
  end
end
