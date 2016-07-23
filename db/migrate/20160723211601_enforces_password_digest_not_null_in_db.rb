class EnforcesPasswordDigestNotNullInDb < ActiveRecord::Migration
  def change
    change_column :users, :password_digest, :string, null: false
  end
end
