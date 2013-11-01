module ProjectsHelper

    def share_project_path(project)
        '/projects/' + project.id.to_s + '/share'
    end

    def create_project_share_path(project)
        '/projects/' + project.id.to_s + '/create_share'
    end

    def project_central_path(project)
        '/projects/' + project.id.to_s + '?view_central=true'
    end

    def extended_project_item_path(project_id, id, central)
        path = project_item_path(project_id, id)
        if central
            path = path + '?view_central=true'
        end
        path
    end

    def project_share_accept_path(code)
        '/projects/accept/' + code
    end

    def item_conflict_path(project_id, item_id)
        '/projects/' + project_id.to_s + '/items/' + item_id.to_s + '/conflict'
    end

    def setup_sync_project_path(project_id)
        "/projects/#{project_id}/setup_sync" 
    end

end
