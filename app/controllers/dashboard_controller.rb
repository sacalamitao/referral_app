class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @referral_code = @user.active_referral_code
    @cashout_request = CashoutRequest.new
    @recent_ledger_entries = @user.ledger_entries.order(occurred_at: :desc).limit(20)
    @recent_cashouts = @user.cashout_requests.order(created_at: :desc).limit(10)
  end
end
