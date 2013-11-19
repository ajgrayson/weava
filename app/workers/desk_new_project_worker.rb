require "desk/desk_api_client"

class DeskNewProjectWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def perform(access_token, access_token_secret, user_id)
        user = User.find_by_id(user_id)
        desk_service = DeskService.new
        desk_client = DeskApiClient.new(access_token, access_token_secret)

        at 10, 100, "Fetching site details"

        name = desk_client.get_site_name()

        at 60, 100, "Initializing the project"

        if name and not name[:error]
            desk_project = desk_service.create_project(
                user,
                name[:value],
                access_token,
                access_token_secret)

            if desk_project != nil
                store project_id: desk_project[:id]

                at 80, 100, "Finalizing"

                message = "User #{user.name} created a Desk Project '#{name[:value]}'"
                LogMailer.log_email(message).deliver

                at 100, 100, "Done"
            else
                at 100, 100, "Error"
            end
        else
             at 100, 100, "Error"
        end

    end

end