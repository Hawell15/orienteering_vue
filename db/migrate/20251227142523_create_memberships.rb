class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :runner, null: false, foreign_key: true
      t.references :club, null: false, foreign_key: true
      t.boolean :main

      t.timestamps
    end
  end
end
