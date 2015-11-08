class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.integer :user_id, null: false
      t.string :slack_auth_token, null: false
      t.string :uber_auth_token, null: false
      t.timestamps null: false
    end

    add_index :authorizations, :user_id
    add_index :authorizations, :slack_auth_token
    add_index :authorizations, :uber_auth_token
  end
end
