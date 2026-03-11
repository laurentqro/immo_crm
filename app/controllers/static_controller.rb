class StaticController < ApplicationController
  layout "landing", only: [:index]

  def index
  end

  def about
  end

  def terms
    @agreement = Rails.application.config.agreements.find { it.id == :terms_of_service }
  end

  def privacy
    @agreement = Rails.application.config.agreements.find { it.id == :privacy_policy }
  end

  def reset_app
    # Hotwire Native needs an empty page to route authentication and reset the app.
    # We can't head: 200 because we also need the Turbo JavaScript in <head>.
  end
end
