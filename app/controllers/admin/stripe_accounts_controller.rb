# frozen_string_literal: true

require 'stripe/account_connector'

module Admin
  class StripeAccountsController < Spree::Admin::BaseController
    def connect
      payload = params.permit(:enterprise_id).to_h
      key = Rails.application.secret_key_base
      url_params = { state: JWT.encode(payload, key, 'HS256'), scope: "read_write" }
      redirect_to Stripe::OAuth.authorize_url(url_params), allow_other_host: true
    end

    def destroy
      stripe_account = StripeAccount.find(params[:id])
      authorize! :destroy, stripe_account

      if stripe_account.deauthorize_and_destroy
        flash[:success] = I18n.t('stripe.success_code.disconnected')
      else
        flash[:error] = I18n.t('stripe.error_code.disconnect_failure')
      end

      redirect_to main_app.edit_admin_enterprise_path(stripe_account.enterprise)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t('stripe.error_code.disconnect_failure')
      redirect_to admin_dashboard_path
    end

    def status
      @stripe_account = stripe_account_status

      respond_to do |format|
        format.html do
          @enterprise = Enterprise.managed_by(spree_current_user)
            .find_by(id: params[:enterprise_id])
          render :status, layout: false
        end
        format.json { render json: @stripe_account }
      end
    end

    private

    def stripe_account_status
      return { status: :stripe_disabled } unless Spree::Config.stripe_connect_enabled

      stripe_account = StripeAccount.find_by(enterprise_id: params[:enterprise_id])
      return { status: :account_missing } unless stripe_account

      authorize! :status, stripe_account

      begin
        status = Stripe::Account.retrieve(stripe_account.stripe_user_id)
        attrs = %i[id business_name charges_enabled]
        status.to_hash.slice(*attrs).merge(status: :connected)
      rescue Stripe::APIError
        { status: :access_revoked }
      end
    end

    def model_class
      StripeAccount
    end
  end
end
