module ApplicationHelper
  def flash_variant(type)
    case type.to_sym
    when :notice, :success
      {
        wrapper: "bg-teal-950/90 text-teal-100 ring-teal-400/30",
        icon: "text-teal-200",
        close: "text-teal-200/80 hover:text-teal-100"
      }
    when :alert, :error
      {
        wrapper: "bg-rose-950/90 text-rose-200 ring-rose-400/30",
        icon: "text-rose-300",
        close: "text-rose-300/80 hover:text-rose-200"
      }
    when :warning
      {
        wrapper: "bg-amber-950/90 text-amber-200 ring-amber-400/30",
        icon: "text-amber-300",
        close: "text-amber-300/80 hover:text-amber-200"
      }
    when :info
      {
        wrapper: "bg-cyan-950/90 text-cyan-100 ring-cyan-400/30",
        icon: "text-cyan-200",
        close: "text-cyan-200/80 hover:text-cyan-100"
      }
    else
      {
        wrapper: "bg-slate-800 text-slate-100 ring-slate-400/30",
        icon: "text-slate-200",
        close: "text-slate-300/80 hover:text-slate-100"
      }
    end
  end

  def ledger_type_badge(entry_type)
    normalized = entry_type.to_s.downcase

    if normalized == "debit"
      {
        label: "debit",
        style: "background-color:#fee2e2;color:#b91c1c;",
        icon: :debit
      }
    else
      {
        label: "credit",
        style: "background-color:#dcfce7;color:#15803d;",
        icon: :credit
      }
    end
  end

  def ledger_amount_pill(amount_cents, entry_type)
    amount = amount_cents.to_i.abs
    debit = entry_type.to_s.downcase == "debit"

    {
      label: "#{debit ? '-' : ''}#{number_to_currency(amount / 100.0, precision: 2)}",
      style: debit ? "background-color:#fee2e2;color:#b91c1c;" : "background-color:#dcfce7;color:#15803d;"
    }
  end

  def ledger_summary_pill(value_cents, variant: :neutral, signed: false)
    value = value_cents.to_i
    currency_value = number_to_currency(value.abs / 100.0, precision: 2)
    label_value = if signed
      value.positive? ? "+#{currency_value}" : value.negative? ? "-#{currency_value}" : currency_value
    else
      currency_value
    end

    classes = case variant.to_sym
    when :success
                "bg-emerald-100 text-emerald-800"
    when :danger
                "bg-rose-100 text-rose-800"
    else
                "bg-slate-100 text-slate-800"
    end

    {
      label: label_value,
      style: case variant.to_sym
             when :success
               "background-color:#dcfce7;color:#166534;"
             when :danger
               "background-color:#fee2e2;color:#991b1b;"
             else
               "background-color:#e2e8f0;color:#1e293b;"
             end
    }
  end
end
