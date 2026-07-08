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

ActiveRecord::Schema[7.1].define(version: 2026_07_08_100003) do
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

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.string "commentable_type"
    t.integer "commentable_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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
    t.index ["contact_phone"], name: "index_whatsapp_conversations_on_contact_phone", unique: true
    t.index ["contact_type", "contact_id"], name: "index_whatsapp_conversations_on_contact_type_and_contact_id"
    t.index ["last_message_at"], name: "index_whatsapp_conversations_on_last_message_at"
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
    t.index ["user_id"], name: "index_whatsapp_templates_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "follow_ups", "leads"
  add_foreign_key "follow_ups", "users"
  add_foreign_key "whatsapp_messages", "users"
  add_foreign_key "whatsapp_messages", "whatsapp_conversations"
  add_foreign_key "whatsapp_templates", "users"
end
