class LogGenericUpdate < ActiveRecord::Migration
  def self.up
		add_column :log_cart_usages, :host, :string;
		add_column :log_collection_group_usages, :host, :string;
		add_column :log_consults, :host, :string;
		add_column :log_facette_usages, :host, :string;
		add_column :log_mail_usages, :host, :string;
		add_column :log_print_usages, :host, :string;
		add_column :log_rebonce_usages, :host, :string;
		add_column :log_rss_usages, :host, :string;
		add_column :log_search_words, :host, :string;
  end

  def self.down
		remove_column :log_cart_usages, :host;
		remove_column :log_collection_group_usages, :host;
		remove_column :log_consults, :host;
		remove_column :log_facette_usages, :host;
		remove_column :log_mail_usages, :host;
		remove_column :log_print_usages, :host;
		remove_column :log_rebonce_usages, :host;
		remove_column :log_rss_usages, :host;
		remove_column :log_search_words, :host;
  end
end
