class CreateRunners < ActiveRecord::Migration[8.0]
  def change
    create_table :runners do |t|
      t.string :runner_name
      t.string :surname
      t.integer :yob, default: "2025"
      t.string :gender
      t.integer :wre_id
      t.date :category_valid, default: "2100-01-01"
      t.integer :sprint_wre_rang
      t.integer :forest_wre_rang
      t.integer :sprint_wre_place
      t.integer :forest_wre_place
      t.string :checksum
      t.boolean :license, default: false
      t.references :club, null: false, foreign_key: true, default: 1
      t.references :category, null: false, foreign_key: true, default: 10
      t.references :best_category, default: 10

      t.timestamps
    end
  end
end
