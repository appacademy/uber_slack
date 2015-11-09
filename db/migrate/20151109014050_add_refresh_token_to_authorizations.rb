class AddRefreshTokenToAuthorizations < ActiveRecord::Migration
  def change
    add_column :authorizations, :uber_refresh_token, :string
    add_column :authorizations, :uber_access_token_expiration_time, :datetime
  end
end
