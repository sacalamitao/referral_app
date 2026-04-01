ActiveAdmin.register_page "Manual Rewards" do
  menu priority: 7

  EVENT_TYPE_OPTIONS = WebhookEvent.event_types.keys.freeze

  content title: "Manual Rewards" do
    panel "Create Manual Reward" do
      para "Use this form to manually process rewards using the same pipeline as webhook events."

      active_admin_form_for :manual_reward, url: admin_manual_rewards_create_path, method: :post do |f|
        f.inputs do
          f.input :event_type,
                  as: :select,
                  collection: EVENT_TYPE_OPTIONS.map { |event_type| [ event_type.humanize, event_type ] },
                  include_blank: false,
                  selected: "registration"
          f.input :referral_code, required: true
          f.input :referred_user_email, required: true
          f.input :reward_amount,
                  label: "Reward amount",
                  hint: "Enter whole amount (e.g., 20 or 20.50).",
                  required: true,
                  input_html: { min: 0.01, step: 0.01, placeholder: "e.g. 20.50" }
        end

        f.actions do
          f.action :submit, label: "Process Manual Reward"
        end
      end
    end
  end

  page_action :create, method: :post do
    result = Rewards::ManualAward.call(
      admin_user: current_admin_user,
      event_type: reward_params[:event_type],
      referral_code: reward_params[:referral_code],
      referred_user_email: reward_params[:referred_user_email],
      reward_amount: reward_params[:reward_amount]
    )

    if result.success?
      redirect_to admin_webhook_event_path(result.data.fetch(:webhook_event)), notice: "Manual reward processed successfully"
    else
      redirect_to admin_manual_rewards_path, alert: result.error_message
    end
  end

  controller do
    private

    def reward_params
      if params[:manual_reward].present?
        params.require(:manual_reward).permit(:event_type, :referral_code, :referred_user_email, :reward_amount)
      else
        params.permit(:event_type, :referral_code, :referred_user_email, :reward_amount)
      end
    end
  end
end
