class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Tells Rails to treat the text column as a structured JSON Hash
  serialize :avo_preferences, type: Hash, coder: JSON
end
