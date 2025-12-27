class CreateResults < ActiveRecord::Migration[8.1]
  def change
    create_table :results do |t|
      t.integer :place
      t.integer :time
      t.integer :wre_points
      t.date :date
      t.integer :ecn_points
      t.string :status
      t.references :membership, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true, default: 10
      t.references :group, null: false, foreign_key: true, default: 1

      t.timestamps
    end
  end
end
