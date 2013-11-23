require 'securerandom'

class Project < ActiveRecord::Base
    has_many :project_roles
    has_many :users, through: :project_roles

    validates :name , presence: true
end
