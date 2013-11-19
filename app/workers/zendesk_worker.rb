class ZendeskWorker

    include Sidekiq::Worker

    def perform(project_id, user_id)
        # project = Project.find_by_id(project_id)
        # user = User.find_by_id(user_id)

        # message = "User #{user.name} started a Zendesk Import for project #{project.name}"

        # LogMailer.log_email(message).deliver

        # zd_service = ZendeskService.new

        # categories = zd_service.fetch_categories
        # sections = zd_service.fetch_sections


    end

end