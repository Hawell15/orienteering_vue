class Group < ApplicationRecord
  belongs_to :competition
  has_many :results, dependent: :destroy
end
