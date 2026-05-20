class ChangeEcnPointsToFloatInResults < ActiveRecord::Migration[8.1]
  def change
    change_column :results, :ecn_points, :float
  end
end
