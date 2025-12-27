class Result < ApplicationRecord
  belongs_to :membership
  belongs_to :category
  belongs_to :group
end
