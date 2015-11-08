class ChangeSlackUserIdType < ActiveRecord::Migration
  def change
  	change_table :authorizations do |t|
      t.change :slack_user_id, :string
    end
  end
end
