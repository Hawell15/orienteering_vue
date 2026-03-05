class ChangeAlternativeClubNamesType < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :alternative_club_names, :string, default: [], array: true
    remove_column :clubs, :alternative_club_name
  end
end
