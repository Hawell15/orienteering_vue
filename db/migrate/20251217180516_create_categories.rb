# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :category_name
      t.string :full_name
      t.float :points
      t.integer :validaty_period, default: 2

      t.timestamps
    end
  end
end
