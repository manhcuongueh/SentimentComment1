class Post < ApplicationRecord
    has_many :comments, dependent: :destroy
    belongs_to :user
    attr_accessor :code
end