class CreateRides < ActiveRecord::Migration
  def change
    create_table :rides do |t|
      t.integer :user_id, null: false
      t.string :surge_confirmation_id

      t.timestamps null: false
    end
  end
end
