class User < ActiveRecord::Base
    validates :email, presence: true

    has_many :project_roles
    has_many :projects, through: :project_roles
end
