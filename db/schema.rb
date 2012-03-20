# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 247) do

  create_table "cached_records", :force => true do |t|
    t.integer  "search_id"
    t.text     "data",          :limit => 2147483647
    t.integer  "collection_id"
    t.datetime "created_at"
    t.integer  "max_recs",                            :default => 0
    t.integer  "status",                              :default => 0
    t.string   "search_time"
    t.integer  "total_hits",                          :default => 0
    t.string   "id_perm"
    t.string   "id_role"
    t.string   "id_lieu"
  end

  add_index "cached_records", ["search_id"], :name => "index_cached_records_on_search_id"

  create_table "cached_searches", :force => true do |t|
    t.string   "query_string"
    t.string   "query_type"
    t.string   "collection_set"
    t.datetime "created_at"
    t.boolean  "in_cache",         :default => false
    t.datetime "cache_updated_at"
    t.integer  "max_recs",         :default => 0
  end

  add_index "cached_searches", ["cache_updated_at", "in_cache"], :name => "index_cached_searches_on_cache_updated_at_and_in_cache"
  add_index "cached_searches", ["created_at"], :name => "index_cached_searches_on_created_at"
  add_index "cached_searches", ["query_string", "query_type", "collection_set"], :name => "query_set_index"

  create_table "collection_group_members", :force => true do |t|
    t.integer "collection_group_id"
    t.integer "collection_id"
    t.boolean "default_on",          :default => false
    t.text    "filter_query"
  end

  add_index "collection_group_members", ["collection_group_id"], :name => "index_collection_group_members_on_collection_group_id"
  add_index "collection_group_members", ["collection_id"], :name => "index_collection_group_members_on_collection_id"

  create_table "collection_groups", :force => true do |t|
    t.string  "name"
    t.string  "full_name"
    t.text    "description"
    t.boolean "enabled",                 :default => false
    t.boolean "display_advanced_search", :default => false
    t.integer "tab_id",                  :default => 0
    t.integer "rank"
  end

  create_table "collections", :force => true do |t|
    t.string   "name"
    t.text     "alt_name"
    t.string   "conn_type"
    t.string   "host"
    t.text     "user"
    t.text     "pass"
    t.string   "record_schema"
    t.text     "definition"
    t.integer  "isword"
    t.text     "url"
    t.string   "mat_type",           :default => "Article"
    t.string   "virtual"
    t.text     "vendor_url"
    t.string   "bib_attr"
    t.integer  "proxy",              :default => 1
    t.datetime "harvested"
    t.integer  "is_parent",          :default => 0
    t.text     "filter_query"
    t.boolean  "has_right",          :default => false
    t.text     "class_handle_right"
    t.string   "harvest_day",        :default => "0123456"
    t.boolean  "is_private",         :default => false
    t.string   "oai_set"
    t.string   "availability"
    t.boolean  "actions_allowed",    :default => false
    t.string   "definition_search",  :default => "creator=1003;author=1003;subject=21;issn=8;isbn=7;callnum=16;publisher=1018;title=4;keyword=1016"
    t.string   "post_data"
  end

  create_table "comment_user_evaluations", :force => true do |t|
    t.string   "uuid",              :null => false
    t.integer  "comment_id",        :null => false
    t.integer  "comment_relevance", :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "comments", :force => true do |t|
    t.datetime "comment_date"
    t.text     "content",                          :null => false
    t.string   "uuid",                             :null => false
    t.integer  "state"
    t.string   "workflow_manager"
    t.datetime "workflow_date",                    :null => false
    t.integer  "object_type"
    t.string   "object_uid"
    t.string   "title"
    t.integer  "parent_id"
    t.integer  "note_id",           :default => 0
    t.integer  "like_count",        :default => 0
    t.integer  "dont_like_count",   :default => 0
    t.integer  "comment_relevance", :default => 0
    t.integer  "workflow",          :default => 0
  end

  create_table "comments_alerts", :id => false, :force => true do |t|
    t.integer  "[:comment_id, :uuid]", :null => false
    t.integer  "comment_id",           :null => false
    t.string   "uuid",                 :null => false
    t.text     "message"
    t.datetime "send_date"
  end

  create_table "community_users", :primary_key => "[:uuid]", :force => true do |t|
    t.string  "uuid",                                                  :null => false
    t.string  "name"
    t.string  "user_type",                 :default => "default_user"
    t.integer "alerts_availability_count", :default => 0
    t.string  "description"
    t.integer "rss_feeds_count",           :default => 0
    t.integer "searches_history_count",    :default => 0
    t.string  "MD5",                                                   :null => false
  end

  create_table "controls", :force => true do |t|
    t.string  "oai_identifier"
    t.string  "title"
    t.integer "collection_id"
    t.string  "description"
    t.string  "url"
    t.string  "collection_name", :default => ""
  end

  add_index "controls", ["collection_id"], :name => "index_controls_on_collection_id"
  add_index "controls", ["oai_identifier"], :name => "index_controls_on_oai_identifier"

  create_table "coverages", :force => true do |t|
    t.string  "journal_title"
    t.string  "issn"
    t.string  "eissn"
    t.string  "isbn"
    t.string  "start_date"
    t.string  "end_date"
    t.string  "provider"
    t.string  "url"
    t.integer "mod_date"
  end

  add_index "coverages", ["eissn"], :name => "index_coverages_on_eissn"
  add_index "coverages", ["end_date"], :name => "index_coverages_on_end_date"
  add_index "coverages", ["isbn"], :name => "index_coverages_on_isbn"
  add_index "coverages", ["issn"], :name => "index_coverages_on_issn"
  add_index "coverages", ["journal_title"], :name => "index_coverages_on_journal_title"
  add_index "coverages", ["mod_date"], :name => "index_coverages_on_mod_date"
  add_index "coverages", ["provider"], :name => "index_coverages_on_provider"
  add_index "coverages", ["start_date"], :name => "index_coverages_on_start_date"

  create_table "document_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.integer  "collection_id"
    t.integer  "primary_document_type", :default => 1
  end

  add_index "document_types", ["collection_id", "primary_document_type"], :name => "index_document_types_on_collection_id_and_primary_document_type"
  add_index "document_types", ["collection_id"], :name => "index_document_types_on_collection_id"
  add_index "document_types", ["primary_document_type"], :name => "index_document_types_on_primary_document_type"

  create_table "editorial_group_members", :force => true do |t|
    t.integer "collection_group_id"
    t.integer "editorial_id"
    t.integer "rank",                :default => 0
  end

  add_index "editorial_group_members", ["collection_group_id"], :name => "index_editorial_group_members_on_collection_group_id"
  add_index "editorial_group_members", ["editorial_id"], :name => "index_editorial_group_members_on_editorial_id"

  create_table "editorials", :force => true do |t|
    t.string  "label"
    t.text    "html"
    t.boolean "activate", :default => true
  end

  create_table "harvest_schedules", :force => true do |t|
    t.time    "time",                                      :null => false
    t.integer "collection_id",              :default => 0
    t.string  "day",           :limit => 0,                :null => false
  end

  add_index "harvest_schedules", ["collection_id", "day", "time"], :name => "index_harvest_schedules_on_collection_id_and_day_and_time", :unique => true
  add_index "harvest_schedules", ["collection_id"], :name => "index_harvest_schedules_on_collection_id"

  create_table "history_searches", :force => true do |t|
    t.string  "search_input",                          :null => false
    t.string  "search_group",                          :null => false
    t.string  "search_type",                           :null => false
    t.string  "tab_filter",                            :null => false
    t.string  "search_operator1"
    t.string  "search_input2"
    t.string  "search_type2"
    t.string  "search_operator2"
    t.string  "search_input3"
    t.string  "search_type3"
    t.integer "search_tab_subject_id", :default => -1
  end

  create_table "hits", :force => true do |t|
    t.integer "session_id"
    t.integer "search_id"
    t.integer "result_count"
    t.string  "action_type"
    t.text    "data"
  end

  add_index "hits", ["action_type"], :name => "index_hits_on_action_type"
  add_index "hits", ["search_id"], :name => "index_hits_on_search_id"
  add_index "hits", ["session_id"], :name => "index_hits_on_session_id"

  create_table "job_queues", :force => true do |t|
    t.string  "records_id",    :default => "-1"
    t.integer "status",        :default => 0
    t.integer "hits",          :default => 0
    t.string  "error"
    t.integer "thread_id",     :default => 0
    t.string  "database_name", :default => ""
    t.integer "total_hits",    :default => 0
    t.integer "collection_id",                   :null => false
    t.string  "timestamp"
  end

  add_index "job_queues", ["collection_id"], :name => "index_job_queues_on_collection_id"

  create_table "linking_word", :force => true do |t|
    t.integer "id_historical_search"
    t.string  "word"
    t.string  "link_type"
    t.string  "query_type"
  end

  create_table "list_user_records", :id => false, :force => true do |t|
    t.integer  "[:doc_identifier, :doc_collection_id, :uuid, :list_id]",                :null => false
    t.string   "doc_identifier",                                                        :null => false
    t.integer  "doc_collection_id",                                                     :null => false
    t.string   "uuid",                                                                  :null => false
    t.integer  "list_id",                                                               :null => false
    t.datetime "date_insert"
    t.integer  "rank",                                                   :default => 0
  end

  create_table "lists", :force => true do |t|
    t.integer  "state"
    t.string   "title"
    t.text     "ptitle"
    t.text     "description"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "uuid"
    t.datetime "date_public"
    t.datetime "date_end_public"
    t.integer  "notes_count",     :default => 0
    t.float    "notes_avg",       :default => 0.0
    t.integer  "comments_count",  :default => 0
  end

  add_index "lists", ["uuid"], :name => "index_lists_on_uuid"

  create_table "log_cart_usages", :force => true do |t|
    t.string   "idDoc"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "host"
    t.string   "profil"
    t.integer  "first"
  end

  create_table "log_comments", :force => true do |t|
    t.string   "host"
    t.string   "object_uid"
    t.string   "object_type"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "int_add"
    t.string   "profil"
  end

  create_table "log_consult_ressources", :force => true do |t|
    t.integer  "collection_id"
    t.string   "host"
    t.string   "doc_identifier"
    t.string   "profil"
    t.integer  "indoor"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "log_consult_ressources", ["collection_id"], :name => "index_log_consult_ressources_on_collection_id"
  add_index "log_consult_ressources", ["indoor"], :name => "index_log_consult_ressources_on_indoor"

  create_table "log_consults", :force => true do |t|
    t.string   "idDoc"
    t.string   "title"
    t.string   "host"
    t.string   "profil"
    t.string   "action"
    t.string   "date"
    t.string   "vendor_name"
    t.string   "context"
    t.string   "material_type"
    t.string   "theme"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "collection_id"
  end

  create_table "log_facette_usages", :force => true do |t|
    t.string   "facette"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "host"
    t.string   "label"
    t.string   "profil"
  end

  create_table "log_list_consults", :force => true do |t|
    t.integer  "id_list"
    t.string   "title"
    t.string   "host"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "profil"
    t.integer  "create_delete"
  end

  create_table "log_mail_usages", :force => true do |t|
    t.string   "idDoc"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "host"
  end

  create_table "log_notes", :force => true do |t|
    t.string   "host"
    t.string   "object_uid"
    t.string   "object_type"
    t.string   "note"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "int_add"
    t.string   "profil"
  end

  create_table "log_print_usages", :force => true do |t|
    t.string   "idDoc"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "host"
  end

  create_table "log_rebonce_profils", :force => true do |t|
    t.string   "profil"
    t.string   "host"
    t.string   "uuid_md5"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "log_rebonce_tags", :force => true do |t|
    t.string   "host"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "object_type"
    t.string   "object_uid"
    t.string   "profil"
    t.integer  "tag_id"
  end

  create_table "log_rss_usages", :force => true do |t|
    t.string   "rss_url"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "host"
  end

  create_table "log_save_notices", :force => true do |t|
    t.string   "idDoc"
    t.string   "saveIn"
    t.string   "host"
    t.string   "profil"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "log_save_notices", ["saveIn"], :name => "index_log_save_notices_on_saveIn"

  create_table "log_save_requests", :force => true do |t|
    t.integer  "search_history_id"
    t.string   "host"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "profil"
  end

  create_table "log_searches", :force => true do |t|
    t.string   "host"
    t.integer  "search_history_id"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.string   "profil"
    t.string   "context"
    t.integer  "search_tab_subject_id"
  end

  add_index "log_searches", ["context"], :name => "index_log_searches_on_context"

  create_table "log_tags", :force => true do |t|
    t.string   "host"
    t.string   "object_type"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "profil"
    t.string   "object_uid"
    t.integer  "tag_id"
    t.integer  "int_add"
    t.string   "tag_label"
  end

  create_table "manage_droits", :id => false, :force => true do |t|
    t.integer "[:id_perm, :id_role, :id_collection, :id_lieu]", :null => false
    t.string  "id_perm",                                        :null => false
    t.string  "id_role",                                        :null => false
    t.string  "id_lieu",                                        :null => false
    t.integer "id_collection",                                  :null => false
  end

  create_table "manage_permissions", :primary_key => "[:id_perm]", :force => true do |t|
    t.string "id_perm", :null => false
  end

  create_table "manage_roles", :primary_key => "[:id_role]", :force => true do |t|
    t.string "id_role"
  end

  create_table "metadatas", :force => true do |t|
    t.integer "collection_id"
    t.integer "controls_id"
    t.text    "dc_title"
    t.text    "dc_creator"
    t.text    "dc_subject"
    t.text    "dc_description"
    t.text    "dc_publisher"
    t.text    "dc_contributor"
    t.text    "dc_date"
    t.text    "dc_type"
    t.text    "dc_format"
    t.text    "dc_identifier_text"
    t.text    "dc_source"
    t.text    "dc_relation"
    t.text    "dc_coverage"
    t.text    "dc_rights"
    t.text    "osu_volume"
    t.text    "osu_issue"
    t.text    "osu_linking"
    t.string  "osu_openurl"
    t.string  "osu_thumbnail",      :default => ""
    t.string  "dc_language"
    t.string  "dc_identifier"
  end

  add_index "metadatas", ["collection_id"], :name => "index_metadatas_on_collection_id"
  add_index "metadatas", ["controls_id"], :name => "index_metadatas_on_controls_id"
  add_index "metadatas", ["dc_identifier"], :name => "index_metadatas_on_dc_identifier"

  create_table "notes", :force => true do |t|
    t.datetime "note_date"
    t.string   "uuid"
    t.integer  "note"
    t.integer  "object_type"
    t.string   "object_uid"
  end

  create_table "notices", :id => false, :force => true do |t|
    t.integer  "[:doc_identifier, :doc_collection_id]",                  :null => false
    t.string   "doc_identifier",                                         :null => false
    t.integer  "doc_collection_id",                                      :null => false
    t.datetime "created_at"
    t.string   "dc_title"
    t.string   "dc_author"
    t.string   "dc_type"
    t.integer  "notes_count",                           :default => 0
    t.float    "notes_avg",                             :default => 0.0
    t.string   "isbn"
    t.string   "ptitle"
    t.datetime "update_date"
    t.integer  "document_type_id"
  end

  create_table "notices_checks", :force => true do |t|
    t.integer "doc_collection_id", :null => false
    t.string  "doc_identifier",    :null => false
  end

  create_table "objects_counts", :force => true do |t|
    t.integer "object_type"
    t.string  "object_uid"
    t.integer "lists_count",           :default => 0
    t.integer "lists_count_public",    :default => 0
    t.integer "comments_count",        :default => 0
    t.integer "comments_count_public", :default => 0
    t.integer "subscriptions_count",   :default => 0
    t.integer "notices_count",         :default => 0
    t.integer "notices_count_public",  :default => 0
    t.integer "tags_count",            :default => 0
    t.integer "tags_count_public",     :default => 0
  end

  create_table "objects_tags", :force => true do |t|
    t.datetime "tag_date"
    t.string   "uuid",                              :null => false
    t.integer  "tag_id",                            :null => false
    t.integer  "state"
    t.string   "workflow_manager"
    t.datetime "workflow_date",                     :null => false
    t.datetime "last_modified_date",                :null => false
    t.integer  "object_type"
    t.string   "object_uid"
    t.integer  "workflow",           :default => 0
  end

  create_table "portfolio_datas", :force => true do |t|
    t.string  "dc_identifier"
    t.string  "isbn"
    t.string  "issn"
    t.string  "call_num"
    t.string  "last_issue"
    t.string  "audience"
    t.string  "genre"
    t.string  "publisher_country"
    t.string  "copyright"
    t.string  "display_group"
    t.string  "broadcast_group"
    t.string  "license_info"
    t.string  "commercial_number"
    t.string  "binding"
    t.string  "theme"
    t.integer "metadata_id"
    t.boolean "is_available"
    t.string  "indice"
    t.string  "display_groups"
    t.text    "issues"
    t.string  "issue_title"
    t.string  "conservation"
  end

  add_index "portfolio_datas", ["call_num"], :name => "index_portfolio_datas_on_call_num"
  add_index "portfolio_datas", ["dc_identifier", "metadata_id"], :name => "index_portfolio_datas_on_dc_identifier_and_metadata_id", :unique => true
  add_index "portfolio_datas", ["dc_identifier"], :name => "index_portfolio_datas_on_dc_identifier", :unique => true
  add_index "portfolio_datas", ["metadata_id"], :name => "index_portfolio_datas_on_metadata_id", :unique => true

  create_table "primary_document_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.integer  "new_period"
    t.string   "display_icon",  :default => "unknown"
    t.string   "no_image_icon", :default => "unknown"
  end

  add_index "primary_document_types", ["name"], :name => "index_primary_document_types_on_name"

  create_table "providers", :force => true do |t|
    t.string  "provider_name"
    t.string  "title"
    t.string  "url"
    t.string  "article_type"
    t.string  "proxy"
    t.integer "can_resolve",   :default => 1
  end

  add_index "providers", ["provider_name"], :name => "index_providers_on_provider_name"
  add_index "providers", ["title"], :name => "index_providers_on_title"

  create_table "records", :force => true do |t|
    t.text   "title",         :null => false
    t.text   "full_text",     :null => false
    t.string "mat_type",      :null => false
    t.text   "abstract",      :null => false
    t.date   "pub_date",      :null => false
    t.string "journal_url",   :null => false
    t.string "journal_title", :null => false
    t.string "db_name",       :null => false
    t.string "db_url",        :null => false
  end

  create_table "register_search", :force => true do |t|
    t.integer  "mode"
    t.integer  "mobile"
    t.string   "sort_type"
    t.string   "uuid"
    t.string   "collection"
    t.datetime "search_last_date"
  end

  create_table "rejects", :force => true do |t|
    t.string   "name"
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "rss_feeds", :force => true do |t|
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.string   "name",                  :null => false
    t.string   "full_name",             :null => false
    t.integer  "primary_document_type"
    t.integer  "new_docs"
    t.integer  "isbn_issn_nullable"
    t.integer  "collection_group"
    t.string   "solr_request",          :null => false
    t.integer  "update_periodicity"
    t.string   "url"
  end

  create_table "search_tab_filters", :force => true do |t|
    t.string  "label"
    t.string  "field_filter"
    t.integer "search_tab_id"
    t.string  "description"
  end

  create_table "search_tab_subjects", :force => true do |t|
    t.integer  "tab_id"
    t.integer  "parent_id"
    t.string   "label"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.integer  "collection_group_id"
    t.string   "description"
    t.integer  "rank"
    t.boolean  "hide",                :default => false
    t.string   "format",              :default => "request"
    t.string   "url",                 :default => ""
  end

  create_table "search_tabs", :force => true do |t|
    t.string "label"
    t.string "description"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "session_id_idx"

  create_table "site_configs", :force => true do |t|
    t.string   "field"
    t.string   "value"
    t.string   "previous_value"
    t.datetime "updated_at"
  end

  add_index "site_configs", ["field"], :name => "index_site_configs_on_field"

  create_table "subscriptions", :id => false, :force => true do |t|
    t.integer  "[:object, :object_id, :uuid]",                :null => false
    t.string   "object_uid"
    t.integer  "object_type"
    t.datetime "subscription_date"
    t.datetime "check_date"
    t.string   "uuid"
    t.integer  "mail_notification"
    t.datetime "send_mail_date"
    t.datetime "change_state_date"
    t.integer  "state",                        :default => 0
  end

  create_table "tags", :force => true do |t|
    t.string "label",        :null => false
    t.string "label_format"
  end

  create_table "themes", :force => true do |t|
    t.string  "reference", :limit => 10,                :null => false
    t.string  "label",                                  :null => false
    t.integer "sort",                    :default => 0
    t.integer "level",                   :default => 1
    t.string  "parent",    :limit => 10
  end

  add_index "themes", ["reference"], :name => "index_themes_on_reference", :unique => true

  create_table "themes_references", :force => true do |t|
    t.string "ref_theme"
    t.string "ref_source", :null => false
    t.string "source",     :null => false
    t.string "exclusion"
  end

  add_index "themes_references", ["ref_source"], :name => "index_themes_references_on_ref_source"
  add_index "themes_references", ["ref_theme"], :name => "index_themes_references_on_ref_theme"

  create_table "user_records", :id => false, :force => true do |t|
    t.integer  "[:doc_identifier, :doc_collection_id, :uuid]", :null => false
    t.string   "doc_identifier",                               :null => false
    t.integer  "doc_collection_id",                            :null => false
    t.string   "uuid",                                         :null => false
    t.datetime "date_insert"
  end

  create_table "users", :force => true do |t|
    t.string  "name",            :limit => 25
    t.string  "full_name",       :limit => 100
    t.string  "email"
    t.string  "hashed_password"
    t.string  "salt"
    t.boolean "administrator",                  :default => false
  end

  create_table "users_history_searches", :force => true do |t|
    t.string   "uuid",                             :null => false
    t.datetime "save_date"
    t.integer  "results_count",     :default => 0
    t.integer  "id_history_search",                :null => false
  end

  create_table "users_preferences", :force => true do |t|
    t.string  "uuid",                                                      :null => false
    t.integer "all_profile_public",               :default => 1
    t.integer "all_profile_followed",             :default => 0
    t.integer "description_public",               :default => 1
    t.integer "description_followed",             :default => 0
    t.integer "all_lists_public",                 :default => 1
    t.integer "all_lists_followed",               :default => 0
    t.integer "all_comments_public",              :default => 1
    t.integer "all_comments_followed",            :default => 0
    t.integer "all_tags_public",                  :default => 1
    t.integer "all_tags_followed",                :default => 0
    t.integer "all_subscriptions_public",         :default => 1
    t.integer "all_subscriptions_followed",       :default => 0
    t.integer "profile_subscriptions_subscribed", :default => 0
    t.integer "profile_subscriptions_mail_notif", :default => 0
    t.integer "lists_subscriptions_subscribed",   :default => 0
    t.integer "lists_subscriptions_mail_notif",   :default => 0
    t.integer "comments_responses_subscribed",    :default => 0
    t.integer "comments_responses_mail_notif",    :default => 0
    t.integer "comments_lists_subscribed",        :default => 0
    t.integer "comments_lists_mail_notif",        :default => 0
    t.integer "all_comments_subscribed",          :default => 0
    t.integer "all_comments_mail_notif",          :default => 0
    t.integer "all_tags_subscribed",              :default => 0
    t.integer "all_tags_mail_notif",              :default => 0
    t.integer "results_number",                   :default => 25
    t.string  "sort_value",                       :default => "relevance"
  end

  create_table "users_tabs_searches_preferences", :force => true do |t|
    t.string  "uuid",                                :null => false
    t.integer "search_tab",   :default => 1
    t.string  "search_group", :default => "g6"
    t.string  "search_type",  :default => "keyword"
  end

  create_table "volumes", :force => true do |t|
    t.string  "call_num"
    t.integer "collection_id", :null => false
    t.string  "dc_identifier", :null => false
    t.integer "number"
    t.string  "availability"
    t.text    "location"
    t.text    "label"
    t.text    "link_label"
    t.text    "launch_url"
    t.text    "link"
    t.string  "support"
    t.integer "metadata_id"
    t.integer "object_id"
    t.integer "document_id"
    t.integer "barcode"
    t.string  "source"
  end

  add_index "volumes", ["call_num"], :name => "index_volumes_on_call_num"
  add_index "volumes", ["collection_id"], :name => "index_volumes_on_collection_id"
  add_index "volumes", ["dc_identifier", "collection_id"], :name => "index_volumes_on_dc_identifier_and_collection_id"
  add_index "volumes", ["dc_identifier"], :name => "index_volumes_on_dc_identifier"
  add_index "volumes", ["metadata_id"], :name => "index_volumes_on_metadata_id"

end
