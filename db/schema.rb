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

ActiveRecord::Schema[7.1].define(version: 2026_07_18_100004) do
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

  create_table "csat_responses", force: :cascade do |t|
    t.string "token", null: false
    t.string "respondent_type"
    t.integer "respondent_id"
    t.integer "user_id"
    t.integer "service_rating"
    t.integer "support_rating"
    t.boolean "would_recommend"
    t.text "improvement_suggestion"
    t.text "additional_comments"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["respondent_type", "respondent_id"], name: "index_csat_responses_on_respondent_type_and_respondent_id"
    t.index ["submitted_at"], name: "index_csat_responses_on_submitted_at"
    t.index ["token"], name: "index_csat_responses_on_token", unique: true
    t.index ["user_id"], name: "index_csat_responses_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "pan"
    t.string "gst"
    t.string "trademark"
    t.integer "status"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "whatsapp_opt_out", default: false, null: false
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "follow_up_campaign_contacts", force: :cascade do |t|
    t.integer "follow_up_campaign_id", null: false
    t.integer "lead_id"
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
    t.index ["lead_id"], name: "index_follow_up_campaign_contacts_on_lead_id"
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

  create_table "follow_ups", force: :cascade do |t|
    t.integer "lead_id", null: false
    t.text "message", null: false
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0
    t.string "whatsapp_message_id"
    t.text "error_message"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_follow_ups_on_lead_id"
    t.index ["scheduled_at"], name: "index_follow_ups_on_scheduled_at"
    t.index ["status"], name: "index_follow_ups_on_status"
    t.index ["user_id"], name: "index_follow_ups_on_user_id"
  end

  create_table "leads", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "pan"
    t.string "gst"
    t.string "trademark"
    t.integer "status"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.boolean "whatsapp_opt_out", default: false, null: false
    t.index ["user_id"], name: "index_leads_on_user_id"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
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
  add_foreign_key "follow_ups", "leads"
  add_foreign_key "follow_ups", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "whatsapp_messages", "users"
  add_foreign_key "whatsapp_messages", "whatsapp_conversations"
  add_foreign_key "whatsapp_templates", "users"
end
