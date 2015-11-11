class AddOriginAndDestinationToRides < ActiveRecord::Migration
  def change
    add_column :rides, :origin_name, :float
    add_column :rides, :destination_name, :float
  end
end
