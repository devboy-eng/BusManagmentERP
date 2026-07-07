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
    colors = if type == :customer
      status == "active" ? "bg-green-50 text-green-700 border-green-200" : "bg-red-50 text-red-700 border-red-200"
    else
      case status
      when "pending" then "bg-yellow-50 text-yellow-700 border-yellow-200"
      when "not_interested" then "bg-red-50 text-red-700 border-red-200"
      when "work_in_process" then "bg-blue-50 text-blue-700 border-blue-200"
      when "contacted" then "bg-green-50 text-green-700 border-green-200"
      when "follow_up" then "bg-purple-50 text-purple-700 border-purple-200"
      end
    end

    label = status.titleize
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

  def follow_up_status_badge(status)
    colors = case status
    when "pending" then "bg-yellow-50 text-yellow-700 border-yellow-200"
    when "sent" then "bg-green-50 text-green-700 border-green-200"
    when "failed" then "bg-red-50 text-red-700 border-red-200"
    when "cancelled" then "bg-gray-50 text-gray-700 border-gray-200"
    else "bg-gray-50 text-gray-700 border-gray-200"
    end

    content_tag(:span, status.titleize, class: "inline-flex items-center rounded-full border px-2 py-0.5 text-[11px] font-medium #{colors}")
  end
end
