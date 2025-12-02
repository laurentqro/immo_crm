# frozen_string_literal: true

# CRUD controller for Transaction management.
# Handles purchase, sale, and rental transactions with payment tracking.
class TransactionsController < ApplicationController
  include OrganizationScoped

  before_action :set_transaction, only: [:show, :edit, :update, :destroy]

  def index
    @transactions = policy_scope(Transaction).includes(:client)

    # Apply filters
    @transactions = @transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?
    @transactions = @transactions.for_year(params[:year].to_i) if params[:year].present?
    @transactions = @transactions.by_payment_method(params[:payment_method]) if params[:payment_method].present?
    @transactions = @transactions.search(params[:q]) if params[:q].present?

    @transactions = @transactions.recent

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    authorize @transaction
  end

  def new
    @transaction = current_organization.transactions.build
    @transaction.client_id = params[:client_id] if params[:client_id].present?
    authorize @transaction
  end

  def edit
    authorize @transaction
  end

  def create
    @transaction = current_organization.transactions.build(transaction_params)
    authorize @transaction

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to @transaction, notice: "Transaction was successfully created." }
        format.turbo_stream { flash.now[:notice] = "Transaction was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @transaction

    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to @transaction, notice: "Transaction was successfully updated." }
        format.turbo_stream { flash.now[:notice] = "Transaction was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @transaction
    @transaction.discard

    respond_to do |format|
      format.html { redirect_to transactions_path, notice: "Transaction was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Transaction was successfully deleted." }
    end
  end

  private

  def set_transaction
    @transaction = policy_scope(Transaction.with_discarded).find_by(id: params[:id])
    render_not_found unless @transaction
  end

  def transaction_params
    params.expect(transaction: policy(@transaction || Transaction).permitted_attributes)
  end
end
