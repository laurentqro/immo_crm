module Account::Domains
  extend ActiveSupport::Concern

  included do
    self::RESERVED_DOMAINS = [Jumpstart.config.domain]
    self::RESERVED_SUBDOMAINS = %w[app help support]

    # To require a domain or subdomain, add the presence validation
    validates :domain, exclusion: {in: self::RESERVED_DOMAINS, message: :reserved}, uniqueness: {allow_blank: true}
    validates :subdomain, exclusion: {in: self::RESERVED_SUBDOMAINS, message: :reserved}, format: {with: /\A[a-zA-Z0-9]+[a-zA-Z0-9\-_]*[a-zA-Z0-9]+\Z/, message: :format, allow_blank: true}, uniqueness: {allow_blank: true}
  end
end
