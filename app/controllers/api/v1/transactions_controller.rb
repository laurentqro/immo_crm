# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < Api::BaseController
      include ApiOrganizationScoped

      before_action :set_transaction, only: [:show, :update, :destroy, :screen]

      # GET /api/v1/transactions
      def index
        transactions = policy_scope(Transaction).includes(:client)
        transactions = transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?
        transactions = transactions.for_year(params[:year].to_i) if params[:year].present?
        transactions = transactions.by_payment_method(params[:payment_method]) if params[:payment_method].present?
        transactions = transactions.search(params[:q]) if params[:q].present?
        transactions = transactions.recent

        render json: transactions.as_json(include: { client: { only: [:id, :name] } })
      end

      # GET /api/v1/transactions/:id
      def show
        authorize @transaction
        render json: @transaction.as_json(include: { client: { only: [:id, :name] } })
      end

      # POST /api/v1/transactions
      def create
        transaction = current_organization.transactions.build(transaction_params)
        authorize transaction

        if transaction.save
          render json: transaction.as_json, status: :created
        else
          render json: { errors: transaction.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/transactions/:id
      def update
        authorize @transaction

        if @transaction.update(transaction_params)
          render json: @transaction.as_json
        else
          render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/transactions/:id
      def destroy
        authorize @transaction
        @transaction.discard
        head :no_content
      end

      # GET /api/v1/transactions/:id/screen
      def screen
        authorize @transaction, :show?

        result = Transactions::Screen.call(transaction: @transaction)
        render json: result.record
      end

      private

      def set_transaction
        @transaction = policy_scope(Transaction.with_discarded).find_by(id: params[:id])
        render json: { error: "Transaction not found" }, status: :not_found unless @transaction
      end

      def transaction_params
        params.require(:transaction).permit(
          TransactionPolicy.new(pundit_user, Transaction).permitted_attributes
        )
      end
    end
  end
end
