class AddMoreColumnsToRides < ActiveRecord::Migration
  def change
    add_column :rides, :start_latitude, :float
    add_column :rides, :start_longitude, :float
    add_column :rides, :end_latitude, :float
    add_column :rides, :end_longitude, :float
    add_column :rides, :product_id, :string
  end
end
