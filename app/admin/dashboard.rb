# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    today_start = Time.current.beginning_of_day

    users_total = User.count
    users_today = User.where("created_at >= ?", today_start).count

    referrals_total = Referral.count
    referrals_registered = Referral.registered.count
    referrals_qualified = Referral.qualified.count
    referrals_blocked = Referral.blocked.count

    pending_cashouts = CashoutRequest.requested
    pending_cashouts_count = pending_cashouts.count
    pending_cashouts_total_cents = pending_cashouts.sum(:amount_cents)

    rewards_7d_cents = RewardTransaction.where("created_at >= ?", 7.days.ago).sum(:reward_cents)
    rewards_30d_cents = RewardTransaction.where("created_at >= ?", 30.days.ago).sum(:reward_cents)

    failed_webhooks_24h = WebhookEvent.failed.where("created_at >= ?", 24.hours.ago).count

    qualified_rate = referrals_total.positive? ? ((referrals_qualified.to_f / referrals_total) * 100.0) : 0.0
    blocked_rate = referrals_total.positive? ? ((referrals_blocked.to_f / referrals_total) * 100.0) : 0.0
    registered_rate = referrals_total.positive? ? ((referrals_registered.to_f / referrals_total) * 100.0) : 0.0

    div style: "display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin-bottom:16px;" do
      div style: "background:#fff;border:1px solid #e5e7eb;border-radius:10px;padding:14px;box-shadow:0 1px 2px rgba(0,0,0,.03);" do
        para "Users", style: "margin:0;color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;"
        h3 users_total.to_s, style: "margin:6px 0 2px;font-size:26px;font-weight:700;color:#0f172a;"
        para "#{users_today} joined today", style: "margin:0;color:#64748b;font-size:12px;"
      end

      div style: "background:#fff;border:1px solid #e5e7eb;border-radius:10px;padding:14px;box-shadow:0 1px 2px rgba(0,0,0,.03);" do
        para "Referrals", style: "margin:0;color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;"
        h3 referrals_total.to_s, style: "margin:6px 0 2px;font-size:26px;font-weight:700;color:#0f172a;"
        para "#{helpers.number_to_percentage(qualified_rate, precision: 1)} qualified", style: "margin:0;color:#64748b;font-size:12px;"
      end

      div style: "background:#fff;border:1px solid #e5e7eb;border-radius:10px;padding:14px;box-shadow:0 1px 2px rgba(0,0,0,.03);" do
        para "Rewards (7 days)", style: "margin:0;color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;"
        h3 helpers.number_to_currency(rewards_7d_cents.to_f / 100, precision: 2), style: "margin:6px 0 2px;font-size:26px;font-weight:700;color:#0f172a;"
        para "30 days: #{helpers.number_to_currency(rewards_30d_cents.to_f / 100, precision: 2)}", style: "margin:0;color:#64748b;font-size:12px;"
      end

      div style: "background:#fff;border:1px solid #e5e7eb;border-radius:10px;padding:14px;box-shadow:0 1px 2px rgba(0,0,0,.03);" do
        para "Pending Cashouts", style: "margin:0;color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;"
        h3 pending_cashouts_count.to_s, style: "margin:6px 0 2px;font-size:26px;font-weight:700;color:#0f172a;"
        para helpers.number_to_currency(pending_cashouts_total_cents.to_f / 100, precision: 2), style: "margin:0;color:#64748b;font-size:12px;"
      end
    end

    columns do
      column do
        panel "Referral Funnel" do
          div style: "margin-bottom:12px;" do
            para "Registered", style: "margin:0 0 6px;font-size:12px;color:#475569;font-weight:600;"
            div style: "height:10px;background:#e2e8f0;border-radius:999px;overflow:hidden;" do
              div style: "width:#{registered_rate}%;height:100%;background:#334155;" do
              end
            end
            para "#{referrals_registered} (#{helpers.number_to_percentage(registered_rate, precision: 1)})", style: "margin:6px 0 0;font-size:12px;color:#64748b;"
          end

          div style: "margin-bottom:12px;" do
            para "Qualified", style: "margin:0 0 6px;font-size:12px;color:#475569;font-weight:600;"
            div style: "height:10px;background:#dbeafe;border-radius:999px;overflow:hidden;" do
              div style: "width:#{qualified_rate}%;height:100%;background:#2563eb;" do
              end
            end
            para "#{referrals_qualified} (#{helpers.number_to_percentage(qualified_rate, precision: 1)})", style: "margin:6px 0 0;font-size:12px;color:#64748b;"
          end

          div do
            para "Blocked", style: "margin:0 0 6px;font-size:12px;color:#475569;font-weight:600;"
            div style: "height:10px;background:#fee2e2;border-radius:999px;overflow:hidden;" do
              div style: "width:#{blocked_rate}%;height:100%;background:#dc2626;" do
              end
            end
            para "#{referrals_blocked} (#{helpers.number_to_percentage(blocked_rate, precision: 1)})", style: "margin:6px 0 0;font-size:12px;color:#64748b;"
          end
        end

        panel "Core KPIs" do
          ul do
            li "Users: #{users_total}"
            li "New users today: #{users_today}"
            li "Referrals total: #{referrals_total}"
            li "Qualified referrals: #{referrals_qualified}"
            li "Blocked referrals: #{referrals_blocked}"
          end
        end

        panel "Financial Snapshot" do
          ul do
            li "Rewards (7d): #{helpers.number_to_currency(rewards_7d_cents.to_f / 100, precision: 2)}"
            li "Rewards (30d): #{helpers.number_to_currency(rewards_30d_cents.to_f / 100, precision: 2)}"
            li "Pending cashouts: #{pending_cashouts_count}"
            li "Pending cashout total: #{helpers.number_to_currency(pending_cashouts_total_cents.to_f / 100, precision: 2)}"
          end
        end
      end

      column do
        panel "Action Required" do
          div style: "display:flex;gap:8px;align-items:center;justify-content:space-between;" do
            status_tag(pending_cashouts_count.positive? ? "warning" : "ok", label: "Cashouts #{pending_cashouts_count}")
            status_tag(failed_webhooks_24h.positive? ? "error" : "ok", label: "Webhook failures #{failed_webhooks_24h}")
          end
        end

        panel "Quick Actions" do
          ul do
            li link_to("Review Cashouts", "/admin/cashout_requests")
            li link_to("View Failed Webhooks", "/admin/webhook_events")
            li link_to("Inspect Referrals", "/admin/referrals")
            li link_to("Adjust Reward Rules", "/admin/reward_rules")
          end
        end

        panel "Recent Cashout Requests" do
          table_for CashoutRequest.order(created_at: :desc).limit(5) do
            column(:id) { |cashout| link_to(cashout.id, "/admin/cashout_requests/#{cashout.id}") }
            column(:user) { |cashout| cashout.user&.email }
            column(:amount) { |cashout| helpers.number_to_currency(cashout.amount_cents.to_f / 100, precision: 2) }
            column :status
            column :created_at
          end
        end

        panel "Recent Webhook Failures" do
          table_for WebhookEvent.failed.order(created_at: :desc).limit(5) do
            column(:id) { |event| link_to(event.id, "/admin/webhook_events/#{event.id}") }
            column :event_type
            column :error_code
            column :created_at
          end
        end
      end
    end
  end # content
end
