class AddSessionToken < ActiveRecord::Migration
  def change
    add_column :authorizations, :session_token, :string
  end
end
