class CascadeDeleteParentResultFk < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :results, column: :parent_result_id
    add_foreign_key    :results, :results, column: :parent_result_id, on_delete: :cascade
  end
end
