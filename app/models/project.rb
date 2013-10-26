require 'securerandom'

class Project < ActiveRecord::Base
    validates :name , presence: true
    # after_initialize :init

    def path
        user_path = Rails.application.config.git_user_path
        File.join(user_path, 'user' + self.user_id.to_s, self.code.to_s)
    end

    def upstream_path
        core_path = Rails.application.config.git_root_path
        File.join(core_path, self.code.to_s)
    end

    def init
        # Only do this when creating a new project.
        # In all other situations this would be loaded from the db.
        if not self.code
            self.code = SecureRandom.uuid
        end
    end
end
