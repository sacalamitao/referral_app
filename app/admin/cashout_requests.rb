ActiveAdmin.register CashoutRequest do
  permit_params :status, :reviewed_by_admin_user_id, :reviewed_at, :paid_at

  index do
    selectable_column
    id_column
    column :user
    column :amount_cents
    column :payout_method
    column :payout_reference
    column :status
    column :payout_attempts
    column :paypal_payout_status
    column :reviewed_by_admin_user
    column :created_at
    actions
  end

  filter :user
  filter :status
  filter :created_at

  member_action :approve, method: :put do
    resource.update!(
      status: :approved,
      reviewed_by_admin_user: current_admin_user,
      reviewed_at: Time.current
    )

    if resource.payout_method == "paypal"
      redirect_to resource_path, notice: "Cashout approved. Review balance then send via PayPal."
    else
      CashoutPayoutJob.perform_later(resource.id)
      redirect_to resource_path, notice: "Cashout approved"
    end
  end

  member_action :decline, method: :put do
    resource.update!(
      status: :declined,
      reviewed_by_admin_user: current_admin_user,
      reviewed_at: Time.current
    )
    redirect_to resource_path, notice: "Cashout declined"
  end

  member_action :send_paypal, method: :put do
    result = Cashouts::SendPaypalPayout.call(cashout_request: resource, actor: current_admin_user)

    if result.success?
      redirect_to resource_path, notice: "PayPal payout sent successfully"
    else
      redirect_to resource_path, alert: result.error_message
    end
  end

  member_action :reverse_failed, method: :put do
    result = Cashouts::ReverseFailedPayout.call(cashout_request: resource, actor: current_admin_user)

    if result.success?
      redirect_to resource_path, notice: "Failed payout reversed and funds restored to available balance"
    else
      redirect_to resource_path, alert: result.error_message
    end
  end

  action_item :approve, only: :show, if: proc { resource.requested? } do
    link_to "Approve", approve_admin_cashout_request_path(resource), method: :put
  end

  action_item :decline, only: :show, if: proc { resource.requested? } do
    link_to "Decline", decline_admin_cashout_request_path(resource), method: :put
  end

  action_item :send_paypal, only: :show, if: proc { (resource.approved? || resource.payout_failed?) && resource.payout_method == "paypal" } do
    snapshot = paypal_balance_snapshot
    current_cents = snapshot[:available_cents]
    projected_cents = current_cents - resource.amount_cents
    message = [
      "Current PayPal balance: #{helpers.number_to_currency(current_cents / 100.0, precision: 2)}",
      "Payout amount: #{helpers.number_to_currency(resource.amount_cents / 100.0, precision: 2)}",
      "Projected balance after payout: #{helpers.number_to_currency(projected_cents / 100.0, precision: 2)}",
      "",
      "Confirm send payout via PayPal?"
    ].join("\n")

    link_to "Send via PayPal", send_paypal_admin_cashout_request_path(resource), method: :put, data: { confirm: message }
  end

  action_item :reverse_failed, only: :show, if: proc { resource.payout_failed? } do
    link_to "Reverse Failed Payout", reverse_failed_admin_cashout_request_path(resource), method: :put,
            data: { confirm: "This will cancel the cashout and restore funds to user available balance. Continue?" }
  end

  show do
    snapshot = paypal_balance_snapshot
    attributes_table do
      row :id
      row :user
      row(:amount) { helpers.number_to_currency(resource.amount_cents / 100.0, precision: 2) }
      row :status
      row :payout_method
      row :payout_reference
      row :payout_attempts
      row :reviewed_by_admin_user
      row :reviewed_at
      row :paid_at
      row :payout_sent_at
      row :payout_failed_at
      row :payout_last_error_code
      row :payout_last_error_message
      row :paypal_sender_batch_id
      row :paypal_payout_batch_id
      row :paypal_payout_item_id
      row :paypal_payout_status
      row :created_at
      row :updated_at
    end

    panel "PayPal Balance Snapshot" do
      if snapshot[:available]
        current_cents = snapshot[:available_cents]
        projected_cents = current_cents - resource.amount_cents
        attributes_table_for resource do
          row("Current PayPal Balance") { helpers.number_to_currency(current_cents / 100.0, precision: 2) }
          row("Payout Amount") { helpers.number_to_currency(resource.amount_cents / 100.0, precision: 2) }
          row("Projected New Balance") { helpers.number_to_currency(projected_cents / 100.0, precision: 2) }
        end
      else
        para(snapshot[:error_message])
      end
    end
  end

  controller do
    helper_method :paypal_balance_snapshot

    def paypal_balance_snapshot
      return @paypal_balance_snapshot if defined?(@paypal_balance_snapshot)

      result = Payments::Paypal::FetchBalance.call
      @paypal_balance_snapshot = if result.success?
        {
          available: true,
          available_cents: result.data.fetch(:available_cents),
          currency: result.data.fetch(:currency)
        }
      else
        {
          available: false,
          available_cents: 0,
          currency: "USD",
          error_message: "PayPal balance unavailable: #{result.error_message}"
        }
      end
    end
  end
end
