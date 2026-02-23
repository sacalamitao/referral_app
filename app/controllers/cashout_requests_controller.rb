class CashoutRequestsController < ApplicationController
  before_action :authenticate_user!

  def create
    result = Cashouts::CreateRequest.call(
      user: current_user,
      amount_cents: cashout_request_params[:amount_cents],
      payout_method: cashout_request_params[:payout_method],
      payout_reference: cashout_request_params[:payout_reference]
    )

    if result.success?
      redirect_to authenticated_root_path, notice: "Cashout request submitted"
    else
      redirect_to authenticated_root_path, alert: result.error_message
    end
  end

  private

  def cashout_request_params
    params.require(:cashout_request).permit(:amount_cents, :payout_method, :payout_reference)
  end
end
