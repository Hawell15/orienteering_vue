class AddParentResultToResults < ActiveRecord::Migration[8.1]
  def change
    add_reference :results, :parent_result, foreign_key: { to_table: :results }, null: true, index: true
  end
end
