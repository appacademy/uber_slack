class AddOriginAndDestinationToRides < ActiveRecord::Migration
  def change
    change_column :rides, :origin_name, :string
    change_column :rides, :destination_name, :string
  end
end
