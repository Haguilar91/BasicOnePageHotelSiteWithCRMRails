class Announcement < ApplicationRecord
  extend Mobility
  translates :title, :description, backend: :key_value, type: :text

  validates :title, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :active, inclusion: { in: [true, false] }
end