class EmailShareWorker

    include Sidekiq::Worker

    def perform(project_id, sharing_user_id, invited_user_id, share_id)
        project = Project.find_by_id(project_id)
        sharing_user = User.find_by_id(sharing_user_id)
        invited_user = User.find_by_id(invited_user_id)
        share = ProjectShare.find_by_id(share_id)
        
        LogMailer.share_project_email(project, sharing_user, invited_user, share).deliver
    end

end