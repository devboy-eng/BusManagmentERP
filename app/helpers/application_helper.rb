module ApplicationHelper
  include Pagy::Frontend

  def sort_link(title, column, current_sort, current_direction)
    direction = (current_sort == column.to_s && current_direction == "asc") ? "desc" : "asc"
    arrow_up_class = (current_sort == column.to_s && current_direction == "asc") ? "text-indigo-600" : "text-gray-300"
    arrow_down_class = (current_sort == column.to_s && current_direction == "desc") ? "text-indigo-600" : "text-gray-300"

    link_to url_for(request.query_parameters.merge(sort: column, direction: direction)), class: "group inline-flex items-center gap-1" do
      concat content_tag(:span, title)
      concat content_tag(:span, class: "flex flex-col") {
        concat content_tag(:svg, content_tag(:path, nil, d: "M5 15l7-7 7 7", stroke_linecap: "round", stroke_linejoin: "round"), xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "2", stroke: "currentColor", class: "h-2.5 w-2.5 #{arrow_up_class}")
        concat content_tag(:svg, content_tag(:path, nil, d: "M19 9l-7 7-7-7", stroke_linecap: "round", stroke_linejoin: "round"), xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "2", stroke: "currentColor", class: "h-2.5 w-2.5 -mt-0.5 #{arrow_down_class}")
      }
    end
  end

  def status_badge(status, type = :customer)
    colors = case type
    when :customer
      status == "active" ? "bg-green-50 text-green-700 border-green-200" : "bg-red-50 text-red-700 border-red-200"
    when :vehicle
      case status
      when "active" then "bg-green-50 text-green-700 border-green-200"
      when "inactive" then "bg-gray-50 text-gray-700 border-gray-200"
      when "scrapped" then "bg-red-50 text-red-700 border-red-200"
      else "bg-gray-50 text-gray-700 border-gray-200"
      end
    when :job_card
      case status
      when "checked_in" then "bg-blue-50 text-blue-700 border-blue-200"
      when "inspection_done" then "bg-cyan-50 text-cyan-700 border-cyan-200"
      when "estimate_created", "estimate_sent" then "bg-yellow-50 text-yellow-700 border-yellow-200"
      when "customer_approved", "manager_approved" then "bg-green-50 text-green-700 border-green-200"
      when "in_progress" then "bg-indigo-50 text-indigo-700 border-indigo-200"
      when "completed" then "bg-emerald-50 text-emerald-700 border-emerald-200"
      when "invoiced", "paid" then "bg-green-50 text-green-700 border-green-200"
      when "gate_pass_issued" then "bg-teal-50 text-teal-700 border-teal-200"
      when "cancelled" then "bg-red-50 text-red-700 border-red-200"
      else "bg-gray-50 text-gray-700 border-gray-200"
      end
    else
      case status.to_s
      when "active", "approved", "paid", "completed", "received" then "bg-green-50 text-green-700 border-green-200"
      when "inactive", "draft" then "bg-gray-50 text-gray-700 border-gray-200"
      when "pending", "sent", "partially_received", "partially_paid" then "bg-yellow-50 text-yellow-700 border-yellow-200"
      when "rejected", "cancelled", "failed" then "bg-red-50 text-red-700 border-red-200"
      when "in_progress", "assigned" then "bg-blue-50 text-blue-700 border-blue-200"
      else "bg-gray-50 text-gray-700 border-gray-200"
      end
    end
    label = status.to_s.titleize
    content_tag(:span, label, class: "inline-flex items-center rounded-full border px-2 py-0.5 text-[11px] font-medium #{colors}")
  end

  def whatsapp_status_badge(status)
    colors = case status
    when "queued" then "bg-gray-50 text-gray-700 border-gray-200"
    when "sent" then "bg-blue-50 text-blue-700 border-blue-200"
    when "delivered" then "bg-green-50 text-green-700 border-green-200"
    when "read" then "bg-indigo-50 text-indigo-700 border-indigo-200"
    when "failed" then "bg-red-50 text-red-700 border-red-200"
    else "bg-gray-50 text-gray-700 border-gray-200"
    end

    content_tag(:span, status.titleize, class: "inline-flex items-center rounded-full border px-2 py-0.5 text-[11px] font-medium #{colors}")
  end

  def template_status_badge(status)
    colors = case status
    when "draft" then "bg-gray-50 text-gray-700 border-gray-200"
    when "pending" then "bg-yellow-50 text-yellow-700 border-yellow-200"
    when "approved" then "bg-green-50 text-green-700 border-green-200"
    when "rejected" then "bg-red-50 text-red-700 border-red-200"
    when "paused" then "bg-orange-50 text-orange-700 border-orange-200"
    when "disabled" then "bg-red-50 text-red-700 border-red-200"
    else "bg-gray-50 text-gray-700 border-gray-200"
    end

    label = (status || "draft").titleize
    content_tag(:span, label, class: "inline-flex items-center rounded-full border px-2 py-0.5 text-[11px] font-medium #{colors}")
  end
end
