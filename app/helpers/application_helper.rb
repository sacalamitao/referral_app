module ApplicationHelper
  def flash_variant(type)
    case type.to_sym
    when :notice, :success
      {
        wrapper: "bg-emerald-950/90 text-emerald-200 ring-emerald-400/30",
        icon: "text-emerald-300",
        close: "text-emerald-300/80 hover:text-emerald-200"
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
        wrapper: "bg-blue-950/90 text-blue-200 ring-blue-400/30",
        icon: "text-blue-300",
        close: "text-blue-300/80 hover:text-blue-200"
      }
    else
      {
        wrapper: "bg-slate-800 text-slate-100 ring-slate-400/30",
        icon: "text-slate-200",
        close: "text-slate-300/80 hover:text-slate-100"
      }
    end
  end
end
