class Webhooks < ActiveRecord::Migration
  def change
    add_column :authorizations, :webhook, :string
  end
end
