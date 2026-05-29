class CreateRelayResults < ActiveRecord::Migration[8.1]
  def change
    create_table :relay_results do |t|
      t.integer :place
      t.integer :time
      t.string  :team
      t.date    :date
      t.references :group, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.bigint :results_id, array: true, default: []

      t.timestamps
    end

    add_index :relay_results, :results_id, using: :gin
  end
end
