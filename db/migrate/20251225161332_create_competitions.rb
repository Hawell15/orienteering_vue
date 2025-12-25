class CreateCompetitions < ActiveRecord::Migration[8.0]
  def change
    create_table :competitions do |t|
      t.string :competition_name
      t.date :date
      t.string :location
      t.string :country, default: "Moldova"
      t.string :distance_type
      t.integer :wre_id
      t.string :checksum
      t.boolean :ecn, default: false

      t.timestamps
    end
  end
end
