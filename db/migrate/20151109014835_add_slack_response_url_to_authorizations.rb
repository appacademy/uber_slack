class AddSlackResponseUrlToAuthorizations < ActiveRecord::Migration
  def change
    add_column :authorizations, :slack_response_url, :string
  end
end
