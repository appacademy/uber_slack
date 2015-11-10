class AddMoreColumnsToRides < ActiveRecord::Migration
  def change
    add_column :rides, :request_id, :string
  end
end
