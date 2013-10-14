class User < ActiveRecord::Base
	validates :email, presence: true

    # File.join(base_path, 'user' + user.id, user.code)
end
