require 'project_type'

class DeskService

    def create_project(user, project_name, access_token, access_token_secret)
        project_service = ProjectService.new

        project = project_service.create_project(user, project_name, ProjectType::DESK)

        if not project[:error]
            desk_project = DeskProject.create(
                :project_id => project[:id], 
                :access_token => access_token,
                :access_token_secret => access_token_secret)

            desk_project.save

            return {
                id: desk_project.project_id
            }
        else
            return {
                error: project[:error]
            }
        end
    end

    def import_project(project_id, user_id)
        user = User.find_by_id(user_id)
        project = Project.find_by_id(project_id)
        desk_project = DeskProject.where("project_id = ?", project_id)[0]
        desk_client = DeskApiClient.new(
            desk_project.access_token, desk_project.access_token_secret)

        repo = GitRepo.new(project.upstream_path)

        topics = desk_client.get_topics
        topics.each do |topic|
            repo.create_meta_file(user, topic[:name] + '.topic', {
                    :id => topic[:id],
                    :name => topic[:name],
                    :description => topic[:description]
                }, topic[:description])

            desk_client.get_articles(topic[:id]).each do |article|
                repo.create_meta_file(user, article[:subject] + '.article', {
                        :id => article[:id],
                        :topic_id => topic[:id],
                        :subject => article[:subject]
                    }, article[:body])
            end
        end
    end

end