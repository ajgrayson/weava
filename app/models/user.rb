class User < ActiveRecord::Base
    has_many :projects

    validates :email, presence: true

    # File.join(base_path, 'user' + user.id, user.code)
end
