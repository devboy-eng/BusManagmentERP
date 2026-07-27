# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_07_27_094213) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "auto_reply_rules", force: :cascade do |t|
    t.string "name", null: false
    t.string "trigger_type", default: "keyword"
    t.string "keyword"
    t.text "reply_body", null: false
    t.boolean "active", default: true
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_auto_reply_rules_on_active"
    t.index ["user_id"], name: "index_auto_reply_rules_on_user_id"
  end

  create_table "branches", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "address"
    t.string "city"
    t.string "state", null: false
    t.string "state_code"
    t.string "phone"
    t.string "email"
    t.string "gst_number"
    t.boolean "is_default", default: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_branches_on_code", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.string "commentable_type"
    t.integer "commentable_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "gst"
    t.integer "status"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "whatsapp_opt_out", default: false, null: false
    t.integer "customer_type", default: 0
    t.string "company_name"
    t.string "gst_number"
    t.string "alternate_phone"
    t.string "city"
    t.string "state"
    t.text "notes"
    t.integer "branch_id"
    t.index ["branch_id"], name: "index_customers_on_branch_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "estimate_line_items", force: :cascade do |t|
    t.integer "estimate_id", null: false
    t.string "item_type", null: false
    t.string "description", null: false
    t.integer "spare_part_id"
    t.integer "technician_id"
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.string "unit", default: "pcs"
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_price", precision: 10, scale: 2, default: "0.0"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimate_id"], name: "index_estimate_line_items_on_estimate_id"
    t.index ["spare_part_id"], name: "index_estimate_line_items_on_spare_part_id"
    t.index ["technician_id"], name: "index_estimate_line_items_on_technician_id"
  end

  create_table "estimates", force: :cascade do |t|
    t.integer "job_card_id", null: false
    t.string "estimate_number", null: false
    t.integer "revision", default: 1
    t.decimal "labor_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "parts_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.string "tax_type", default: "cgst_sgst"
    t.decimal "cgst_rate", precision: 5, scale: 2, default: "9.0"
    t.decimal "sgst_rate", precision: 5, scale: 2, default: "9.0"
    t.decimal "igst_rate", precision: 5, scale: 2, default: "18.0"
    t.decimal "cgst_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "sgst_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "igst_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_tax", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.string "discount_reason"
    t.decimal "grand_total", precision: 10, scale: 2, default: "0.0"
    t.text "notes"
    t.integer "status", default: 0
    t.boolean "is_additional", default: false
    t.integer "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_estimates_on_created_by_id"
    t.index ["estimate_number"], name: "index_estimates_on_estimate_number", unique: true
    t.index ["job_card_id"], name: "index_estimates_on_job_card_id"
  end

  create_table "follow_up_campaign_contacts", force: :cascade do |t|
    t.integer "follow_up_campaign_id", null: false
    t.string "name"
    t.string "phone", null: false
    t.integer "status", default: 0
    t.string "whatsapp_message_id"
    t.text "error_message"
    t.datetime "sent_at"
    t.datetime "delivered_at"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.index ["customer_id"], name: "index_follow_up_campaign_contacts_on_customer_id"
    t.index ["follow_up_campaign_id"], name: "index_follow_up_campaign_contacts_on_follow_up_campaign_id"
    t.index ["status"], name: "index_follow_up_campaign_contacts_on_status"
  end

  create_table "follow_up_campaigns", force: :cascade do |t|
    t.string "name"
    t.integer "whatsapp_template_id", null: false
    t.text "template_variables"
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0
    t.integer "user_id"
    t.integer "total_contacts", default: 0
    t.integer "sent_count", default: 0
    t.integer "delivered_count", default: 0
    t.integer "read_count", default: 0
    t.integer "failed_count", default: 0
    t.integer "expired_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_follow_up_campaigns_on_user_id"
    t.index ["whatsapp_template_id"], name: "index_follow_up_campaigns_on_whatsapp_template_id"
  end

  create_table "inspection_items", force: :cascade do |t|
    t.integer "inspection_id", null: false
    t.string "area", null: false
    t.integer "condition", default: 0
    t.text "notes"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inspection_id"], name: "index_inspection_items_on_inspection_id"
  end

  create_table "inspections", force: :cascade do |t|
    t.integer "job_card_id", null: false
    t.integer "inspected_by_id", null: false
    t.text "general_notes"
    t.integer "overall_condition", default: 0
    t.datetime "inspected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inspected_by_id"], name: "index_inspections_on_inspected_by_id"
    t.index ["job_card_id"], name: "index_inspections_on_job_card_id"
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.integer "spare_part_id", null: false
    t.integer "warehouse_id", null: false
    t.integer "quantity", null: false
    t.integer "movement_type", default: 0
    t.string "reference_type"
    t.integer "reference_id"
    t.text "notes"
    t.integer "performed_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["performed_by_id"], name: "index_inventory_movements_on_performed_by_id"
    t.index ["reference_type", "reference_id"], name: "index_inventory_movements_on_reference_type_and_reference_id"
    t.index ["spare_part_id"], name: "index_inventory_movements_on_spare_part_id"
    t.index ["warehouse_id"], name: "index_inventory_movements_on_warehouse_id"
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.string "item_type", null: false
    t.string "description", null: false
    t.integer "spare_part_id"
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.string "unit", default: "pcs"
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_price", precision: 10, scale: 2, default: "0.0"
    t.string "hsn_code"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
    t.index ["spare_part_id"], name: "index_invoice_line_items_on_spare_part_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "job_card_id", null: false
    t.integer "customer_id", null: false
    t.integer "branch_id", null: false
    t.string "invoice_number", null: false
    t.decimal "labor_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "parts_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.string "tax_type", default: "cgst_sgst"
    t.decimal "cgst_rate", precision: 5, scale: 2, default: "9.0"
    t.decimal "sgst_rate", precision: 5, scale: 2, default: "9.0"
    t.decimal "igst_rate", precision: 5, scale: 2, default: "18.0"
    t.decimal "cgst_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "sgst_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "igst_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_tax", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "grand_total", precision: 10, scale: 2, default: "0.0"
    t.integer "status", default: 0
    t.text "notes"
    t.integer "created_by_id", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_invoices_on_branch_id"
    t.index ["created_by_id"], name: "index_invoices_on_created_by_id"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["job_card_id"], name: "index_invoices_on_job_card_id"
  end

  create_table "job_cards", force: :cascade do |t|
    t.string "job_card_number", null: false
    t.integer "vehicle_id", null: false
    t.integer "customer_id", null: false
    t.integer "branch_id", null: false
    t.integer "service_advisor_id", null: false
    t.integer "service_type_id"
    t.integer "odometer_reading"
    t.text "customer_complaints"
    t.text "advisor_notes"
    t.integer "status", default: 0, null: false
    t.integer "priority", default: 0
    t.datetime "checked_in_at"
    t.datetime "estimated_completion_at"
    t.datetime "work_started_at"
    t.datetime "work_completed_at"
    t.datetime "delivered_at"
    t.string "customer_approval_token"
    t.datetime "customer_approved_at"
    t.text "customer_signature_data"
    t.string "manager_approval_token"
    t.datetime "manager_approved_at"
    t.integer "approved_by_id"
    t.string "gate_pass_number"
    t.datetime "gate_pass_issued_at"
    t.integer "gate_pass_issued_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_job_cards_on_approved_by_id"
    t.index ["branch_id"], name: "index_job_cards_on_branch_id"
    t.index ["customer_approval_token"], name: "index_job_cards_on_customer_approval_token", unique: true
    t.index ["customer_id"], name: "index_job_cards_on_customer_id"
    t.index ["gate_pass_issued_by_id"], name: "index_job_cards_on_gate_pass_issued_by_id"
    t.index ["job_card_number"], name: "index_job_cards_on_job_card_number", unique: true
    t.index ["manager_approval_token"], name: "index_job_cards_on_manager_approval_token", unique: true
    t.index ["service_advisor_id"], name: "index_job_cards_on_service_advisor_id"
    t.index ["service_type_id"], name: "index_job_cards_on_service_type_id"
    t.index ["status"], name: "index_job_cards_on_status"
    t.index ["vehicle_id"], name: "index_job_cards_on_vehicle_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.integer "customer_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "payment_method", default: 0
    t.string "transaction_reference"
    t.text "notes"
    t.integer "received_by_id", null: false
    t.datetime "paid_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["received_by_id"], name: "index_payments_on_received_by_id"
  end

  create_table "purchase_order_items", force: :cascade do |t|
    t.integer "purchase_order_id", null: false
    t.integer "spare_part_id", null: false
    t.integer "ordered_quantity", null: false
    t.integer "received_quantity", default: 0
    t.decimal "unit_cost", precision: 10, scale: 2, null: false
    t.decimal "total_cost", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_order_id"], name: "index_purchase_order_items_on_purchase_order_id"
    t.index ["spare_part_id"], name: "index_purchase_order_items_on_spare_part_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string "po_number", null: false
    t.integer "supplier_id", null: false
    t.integer "warehouse_id", null: false
    t.integer "branch_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.integer "status", default: 0
    t.date "expected_delivery_date"
    t.date "received_date"
    t.text "notes"
    t.integer "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_purchase_orders_on_branch_id"
    t.index ["created_by_id"], name: "index_purchase_orders_on_created_by_id"
    t.index ["po_number"], name: "index_purchase_orders_on_po_number", unique: true
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
    t.index ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id"
  end

  create_table "quick_responses", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.string "shortcode"
    t.integer "user_id"
    t.integer "usage_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shortcode"], name: "index_quick_responses_on_shortcode"
    t.index ["user_id"], name: "index_quick_responses_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scheduled_messages", force: :cascade do |t|
    t.integer "whatsapp_conversation_id", null: false
    t.text "message_body", null: false
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0
    t.string "whatsapp_message_id"
    t.text "error_message"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_at"], name: "index_scheduled_messages_on_scheduled_at"
    t.index ["status", "scheduled_at"], name: "index_scheduled_messages_on_status_and_scheduled_at"
    t.index ["user_id"], name: "index_scheduled_messages_on_user_id"
    t.index ["whatsapp_conversation_id"], name: "index_scheduled_messages_on_whatsapp_conversation_id"
  end

  create_table "service_reminders", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.integer "customer_id", null: false
    t.string "reminder_type"
    t.date "due_date"
    t.integer "odometer_due_at"
    t.integer "status", default: 0
    t.string "whatsapp_message_id"
    t.datetime "sent_at"
    t.text "notes"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_service_reminders_on_created_by_id"
    t.index ["customer_id"], name: "index_service_reminders_on_customer_id"
    t.index ["due_date"], name: "index_service_reminders_on_due_date"
    t.index ["status"], name: "index_service_reminders_on_status"
    t.index ["vehicle_id"], name: "index_service_reminders_on_vehicle_id"
  end

  create_table "service_types", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "base_labor_charge", precision: 10, scale: 2, default: "0.0"
    t.integer "estimated_hours"
    t.boolean "active", default: true
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "spare_parts", force: :cascade do |t|
    t.string "part_number", null: false
    t.string "name", null: false
    t.text "description"
    t.string "category"
    t.string "brand"
    t.string "compatible_makes"
    t.string "unit", default: "pcs"
    t.decimal "selling_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "cost_price", precision: 10, scale: 2, default: "0.0"
    t.integer "reorder_level", default: 5
    t.integer "current_stock", default: 0
    t.string "hsn_code"
    t.integer "warranty_months", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_spare_parts_on_category"
    t.index ["current_stock"], name: "index_spare_parts_on_current_stock"
    t.index ["part_number"], name: "index_spare_parts_on_part_number", unique: true
  end

  create_table "stock_entries", force: :cascade do |t|
    t.integer "spare_part_id", null: false
    t.integer "warehouse_id", null: false
    t.integer "quantity", default: 0
    t.string "batch_number"
    t.string "serial_number"
    t.date "expiry_date"
    t.date "warranty_expiry_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spare_part_id"], name: "index_stock_entries_on_spare_part_id"
    t.index ["warehouse_id"], name: "index_stock_entries_on_warehouse_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_person"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "gst_number"
    t.text "notes"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "technician_assignments", force: :cascade do |t|
    t.integer "job_card_id", null: false
    t.integer "technician_id", null: false
    t.string "task_description"
    t.decimal "estimated_hours", precision: 6, scale: 2
    t.decimal "actual_hours", precision: 6, scale: 2
    t.integer "status", default: 0
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_card_id"], name: "index_technician_assignments_on_job_card_id"
    t.index ["technician_id"], name: "index_technician_assignments_on_technician_id"
  end

  create_table "technicians", force: :cascade do |t|
    t.integer "user_id"
    t.integer "branch_id"
    t.string "name", null: false
    t.string "phone"
    t.string "employee_id"
    t.string "specialization"
    t.decimal "hourly_rate", precision: 8, scale: 2, default: "0.0"
    t.integer "status", default: 0
    t.date "joined_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_technicians_on_branch_id"
    t.index ["employee_id"], name: "index_technicians_on_employee_id", unique: true
    t.index ["user_id"], name: "index_technicians_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "phone"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.text "permissions"
    t.string "otp_code"
    t.datetime "otp_sent_at"
    t.boolean "otp_enabled", default: false, null: false
    t.integer "branch_id"
    t.index ["branch_id"], name: "index_users_on_branch_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "registration_number", null: false
    t.string "vin"
    t.string "make", null: false
    t.string "model"
    t.integer "year_of_manufacture"
    t.string "engine_number"
    t.string "chassis_number"
    t.string "fuel_type"
    t.integer "seating_capacity"
    t.integer "current_odometer"
    t.string "color"
    t.string "insurance_provider"
    t.string "insurance_policy_number"
    t.date "insurance_expiry_date"
    t.date "fitness_certificate_expiry"
    t.date "permit_expiry_date"
    t.date "puc_expiry_date"
    t.text "notes"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_vehicles_on_customer_id"
    t.index ["registration_number"], name: "index_vehicles_on_registration_number", unique: true
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name", null: false
    t.text "address"
    t.string "contact_phone"
    t.integer "branch_id"
    t.boolean "is_default", default: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_warehouses_on_branch_id"
  end

  create_table "whatsapp_conversations", force: :cascade do |t|
    t.string "contact_phone", null: false
    t.string "contact_name"
    t.string "contact_type"
    t.integer "contact_id"
    t.text "last_message_body"
    t.datetime "last_message_at"
    t.integer "unread_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assigned_user_id"
    t.index ["assigned_user_id"], name: "index_whatsapp_conversations_on_assigned_user_id"
    t.index ["contact_phone"], name: "index_whatsapp_conversations_on_contact_phone", unique: true
    t.index ["contact_type", "contact_id"], name: "index_whatsapp_conversations_on_contact_type_and_contact_id"
    t.index ["last_message_at"], name: "index_whatsapp_conversations_on_last_message_at"
  end

  create_table "whatsapp_menus", force: :cascade do |t|
    t.string "name", null: false
    t.string "header_text"
    t.text "body_text", null: false
    t.string "footer_text"
    t.string "button_text", default: "Menu"
    t.text "menu_items"
    t.string "trigger_keyword"
    t.boolean "active", default: true
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_whatsapp_menus_on_active"
    t.index ["trigger_keyword"], name: "index_whatsapp_menus_on_trigger_keyword"
  end

  create_table "whatsapp_messages", force: :cascade do |t|
    t.string "recipient_type"
    t.integer "recipient_id"
    t.string "recipient_name"
    t.string "recipient_phone"
    t.text "message_body"
    t.string "whatsapp_message_id"
    t.integer "status", default: 0
    t.text "error_message"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "direction", default: "outgoing"
    t.integer "whatsapp_conversation_id"
    t.string "message_type", default: "text"
    t.string "media_url"
    t.string "media_mime_type"
    t.string "media_filename"
    t.string "media_caption"
    t.string "reaction_emoji"
    t.string "context_message_id"
    t.text "metadata"
    t.index ["message_type"], name: "index_whatsapp_messages_on_message_type"
    t.index ["recipient_type", "recipient_id"], name: "index_whatsapp_messages_on_recipient_type_and_recipient_id"
    t.index ["user_id"], name: "index_whatsapp_messages_on_user_id"
    t.index ["whatsapp_conversation_id", "created_at"], name: "idx_on_whatsapp_conversation_id_created_at_858d582181"
    t.index ["whatsapp_conversation_id"], name: "index_whatsapp_messages_on_whatsapp_conversation_id"
  end

  create_table "whatsapp_settings", force: :cascade do |t|
    t.string "phone_number_id"
    t.string "access_token"
    t.string "business_account_id"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "verify_token"
    t.string "webhook_url"
    t.string "app_secret"
    t.string "app_id"
    t.string "quality_rating"
    t.string "messaging_limit"
    t.datetime "quality_updated_at"
    t.string "phone_display_number"
    t.string "verified_name"
    t.string "name_status"
    t.string "phone_status"
    t.string "code_verification_status"
    t.string "platform_type"
    t.string "business_about"
    t.text "business_description"
    t.string "business_address"
    t.string "business_email"
    t.text "business_websites"
    t.string "business_vertical"
    t.text "profile_picture_url"
    t.datetime "profile_synced_at"
  end

  create_table "whatsapp_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", null: false
    t.string "category"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "draft"
    t.string "header_type", default: "none"
    t.string "header_text"
    t.string "header_media_url"
    t.string "language", default: "en"
    t.string "footer"
    t.string "meta_template_id"
    t.string "template_type", default: "standard"
    t.text "carousel_cards"
    t.text "buttons"
    t.index ["user_id"], name: "index_whatsapp_templates_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customers", "branches"
  add_foreign_key "estimate_line_items", "estimates"
  add_foreign_key "estimate_line_items", "spare_parts"
  add_foreign_key "estimate_line_items", "technicians"
  add_foreign_key "estimates", "job_cards"
  add_foreign_key "estimates", "users", column: "created_by_id"
  add_foreign_key "inspection_items", "inspections"
  add_foreign_key "inspections", "job_cards"
  add_foreign_key "inspections", "users", column: "inspected_by_id"
  add_foreign_key "inventory_movements", "spare_parts"
  add_foreign_key "inventory_movements", "users", column: "performed_by_id"
  add_foreign_key "inventory_movements", "warehouses"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoice_line_items", "spare_parts"
  add_foreign_key "invoices", "branches"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "job_cards"
  add_foreign_key "invoices", "users", column: "created_by_id"
  add_foreign_key "job_cards", "branches"
  add_foreign_key "job_cards", "customers"
  add_foreign_key "job_cards", "service_types"
  add_foreign_key "job_cards", "users", column: "approved_by_id"
  add_foreign_key "job_cards", "users", column: "gate_pass_issued_by_id"
  add_foreign_key "job_cards", "users", column: "service_advisor_id"
  add_foreign_key "job_cards", "vehicles"
  add_foreign_key "payments", "customers"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payments", "users", column: "received_by_id"
  add_foreign_key "purchase_order_items", "purchase_orders"
  add_foreign_key "purchase_order_items", "spare_parts"
  add_foreign_key "purchase_orders", "branches"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "purchase_orders", "users", column: "created_by_id"
  add_foreign_key "purchase_orders", "warehouses"
  add_foreign_key "service_reminders", "customers"
  add_foreign_key "service_reminders", "users", column: "created_by_id"
  add_foreign_key "service_reminders", "vehicles"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "stock_entries", "spare_parts"
  add_foreign_key "stock_entries", "warehouses"
  add_foreign_key "technician_assignments", "job_cards"
  add_foreign_key "technician_assignments", "technicians"
  add_foreign_key "technicians", "branches"
  add_foreign_key "technicians", "users"
  add_foreign_key "users", "branches"
  add_foreign_key "vehicles", "customers"
  add_foreign_key "warehouses", "branches"
  add_foreign_key "whatsapp_messages", "users"
  add_foreign_key "whatsapp_messages", "whatsapp_conversations"
  add_foreign_key "whatsapp_templates", "users"
end
