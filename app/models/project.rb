require 'securerandom'

class Project < ActiveRecord::Base
    validates :name , presence: true
    # after_initialize :init

    def init
        # Only do this when creating a new project.
        # In all other situations this would be loaded from the db.
        if not self.code
            base_path = Rails.application.config.git_root_path
            self.code = SecureRandom.uuid
            self.path = File.join(base_path, 'user' + self.user_id.to_s, self.code.to_s)
        end
    end
end
