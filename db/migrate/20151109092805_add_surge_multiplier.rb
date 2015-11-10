class AddSurgeMultiplier < ActiveRecord::Migration
  def change
    add_column :rides, :surge_multiplier, :float
  end
end
