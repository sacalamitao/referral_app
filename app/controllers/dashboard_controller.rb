class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    per_page = 10

    @user = current_user
    @referral_code = @user.active_referral_code
    @cashout_request = CashoutRequest.new

    ledger_scope = @user.ledger_entries.order(occurred_at: :desc)
    @ledger_page = [ params.fetch(:ledger_page, 1).to_i, 1 ].max
    @ledger_total_count = ledger_scope.count
    @ledger_total_pages = [ (@ledger_total_count.to_f / per_page).ceil, 1 ].max
    @ledger_page = [ @ledger_page, @ledger_total_pages ].min
    @recent_ledger_entries = ledger_scope.offset((@ledger_page - 1) * per_page).limit(per_page)

    cashouts_scope = @user.cashout_requests.order(created_at: :desc)
    @cashouts_page = [ params.fetch(:cashouts_page, 1).to_i, 1 ].max
    @cashouts_total_count = cashouts_scope.count
    @cashouts_total_pages = [ (@cashouts_total_count.to_f / per_page).ceil, 1 ].max
    @cashouts_page = [ @cashouts_page, @cashouts_total_pages ].min
    @recent_cashouts = cashouts_scope.offset((@cashouts_page - 1) * per_page).limit(per_page)
  end
end
