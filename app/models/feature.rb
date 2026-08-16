class Feature < ApplicationRecord
  extend Mobility
  translates :title, backend: :key_value, type: :string
  translates :description, backend: :key_value, type: :text
end
