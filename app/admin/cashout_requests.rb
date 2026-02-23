ActiveAdmin.register CashoutRequest do
  permit_params :status, :reviewed_by_admin_user_id, :reviewed_at, :paid_at

  index do
    selectable_column
    id_column
    column :user
    column :amount_cents
    column :status
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
    CashoutPayoutJob.perform_later(resource.id)
    redirect_to resource_path, notice: "Cashout approved"
  end

  member_action :decline, method: :put do
    resource.update!(
      status: :declined,
      reviewed_by_admin_user: current_admin_user,
      reviewed_at: Time.current
    )
    redirect_to resource_path, notice: "Cashout declined"
  end

  action_item :approve, only: :show, if: proc { resource.requested? } do
    link_to "Approve", approve_admin_cashout_request_path(resource), method: :put
  end

  action_item :decline, only: :show, if: proc { resource.requested? } do
    link_to "Decline", decline_admin_cashout_request_path(resource), method: :put
  end
end

