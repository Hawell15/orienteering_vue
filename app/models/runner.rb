class Runner < ApplicationRecord
  belongs_to :club
  belongs_to :category
  belongs_to :best_category, class_name: "Category"
  has_many :memberships, dependent: :destroy
  has_many :results, through: :memberships
end
