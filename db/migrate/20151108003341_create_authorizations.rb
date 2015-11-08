class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.integer :slack_user_id
      t.string :slack_auth_token
      t.string :oauth_session_token
      t.integer :uber_user_id
      t.string :uber_auth_token
      t.timestamps null: false
    end

    add_index :authorizations, [:slack_user_id, :uber_user_id], unique: true
    add_index :authorizations, :slack_auth_token
    add_index :authorizations, :uber_auth_token
    add_index :authorizations, :oauth_session_token
  end
end
