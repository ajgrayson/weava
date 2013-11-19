require "desk/desk_api_client"

class DeskImportProjectWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    def perform(project_id, user_id)
        store project_id: project_id

        desk_service = DeskService.new

        desk_service.import_project(project_id, user_id)

        at 100, 100, "Done"
    end
end