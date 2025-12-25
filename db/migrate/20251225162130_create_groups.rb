class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :group_name
      t.integer :rang
      t.string :clasa
      t.float :ecn_coeficient
      t.references :competition, null: false, foreign_key: true, default: 1

      t.timestamps
    end
  end
end
