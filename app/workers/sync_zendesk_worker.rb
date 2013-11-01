class SyncZendeskWorker

    include Sidekiq::Worker

    def perform(project_id, user_id)
        project = Project.find_by_id(project_id)
        user = User.find_by_id(user_id)

        message = "User #{user.name} ran Zendesk Sync for project #{project.name}"

        LogMailer.log_email(message).deliver
    end

end