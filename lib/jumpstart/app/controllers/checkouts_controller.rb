class CheckoutsController < ApplicationController
  layout "minimal", only: [:show, :create]

  before_action :authenticate_user_with_sign_up!
  before_action :require_current_account_admin
  before_action :set_plan
  before_action :redirect_if_already_subscribed, only: [:show]
  before_action :handle_past_due_or_unpaid, only: [:show]

  def show
    if Jumpstart.config.stripe?
      set_checkout_session
    elsif Jumpstart.config.lemon_squeezy?
      payment_processor = current_account.set_payment_processor(:lemon_squeezy)
      checkout = payment_processor.checkout(variant_id: @plan.id_for_processor(:lemon_squeezy))
      redirect_to checkout.url, allow_other_host: true
    else
      # Set the payment processor and try to create a Customer if supported to tie the checkout
      payment_processor = current_account.set_payment_processor(Jumpstart.config.payment_processors.first)
      payment_processor.api_record
    end
  rescue Pay::Error => e
    flash[:alert] = e.message
    redirect_to pricing_path
  end

  # Only used by Braintree
  def create
    payment_processor = params[:processor] ? current_account.set_payment_processor(params[:processor]) : current_account.payment_processor
    payment_processor.update_payment_method(params[:payment_method_token])
    args = {
      plan: @plan.id_for_processor(payment_processor.processor),
      trial_period_days: @plan.trial_period_days
    }
    args[:quantity] = current_account.per_unit_quantity if @plan.charge_per_unit?
    payment_processor.subscribe(**args)
    redirect_to root_path, notice: t(".created")
  rescue Pay::ActionRequired => e
    redirect_to pay.payment_path(e.payment.id)
  rescue Pay::Error => e
    flash[:alert] = e.message
    render :new, status: :unprocessable_content
  end

  private

  # Pricing page will only display visible plans, but hidden plans are included here to make customer support easier.
  def set_plan
    @plan = Plan.find_by_prefix_id!(params[:plan])
  rescue ActiveRecord::RecordNotFound
    redirect_to pricing_path
  end

  def set_checkout_session
    payment_processor = current_account.set_payment_processor(:stripe)

    # Only allow trials on the account's first subscription
    trial_allowed = current_account.pay_subscriptions.none?

    subscription_data = {
      metadata: params.fetch(:metadata, {}).permit!.to_h,
      trial_settings: {end_behavior: {missing_payment_method: "pause"}},
      trial_period_days: ((@plan.trial_period_days.to_i > 1 && trial_allowed) ? @plan.trial_period_days : nil)
    }.compact
    args = {
      allow_promotion_codes: true,
      automatic_tax: {enabled: @plan.taxed?},
      consent_collection: {terms_of_service: :required},
      customer_update: {address: :auto},
      mode: :subscription,
      line_items: @plan.id_for_processor(:stripe),
      payment_method_collection: :if_required,
      return_url: checkout_return_url(return_to: params[:return_to]),
      subscription_data: subscription_data,
      ui_mode: :embedded
    }
    args[:quantity] = current_account.per_unit_quantity if @plan.charge_per_unit?
    @checkout_session = payment_processor.checkout(**args)
  end

  def redirect_if_already_subscribed
    redirect_to billing_path, alert: t(".already_subscribed") if current_account.payment_processor&.subscribed?
  end

  def handle_past_due_or_unpaid
    if (subscription = current_account.payment_processor&.subscription) && (subscription.past_due? || subscription.unpaid?)
      redirect_to billing_path
    end
  end
end
