class Cleandatabase < ActiveRecord::Migration
  def change
    remove_column :authorizations, :oauth_session_token, :string
    remove_column :authorizations, :uber_user_id, :string
    remove_column :authorizations, :webhook, :string
  end
end
