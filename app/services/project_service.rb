class ProjectService

    def get_project(project_id, user_id)
        project = Project.find_by_id(project_id)
        if not project or project.user_id != user.id
            project = nil
        end
        project
    end

    # Get all the user projects including
    # shared projects
    def get_projects_for_user(
        user_id)

        projects = []

        my_projects = Project.where("user_id = ?", user_id)
        my_projects.each do |project|
            user = nil
            if not project.owner
                orig_project = Project.where(
                    "code = ? and owner = ?", project.code, true)

                user = User.find_by_id(
                    orig_project.first.user_id)
            else
                user = User.find_by_id(project.user_id)
            end

            projects.push({
                :id => project.id,
                :name => project.name,
                :username => user.name,
                :owned => project.owner,
                :pending => false,
                :share_code => nil
            })
        end

        shares = ProjectShare.where(
            "user_id = ? and (accepted is " + 
                "null or accepted = false)", user_id)

        shares.each do |share|
            project = Project.find_by_id(share.project_id)
            user = User.find_by_id(share.owner_id)
            if project
                projects.push({
                    :id => project.id,
                    :name => project.name,
                    :username => user.name,
                    :owned => false,
                    :pending => true,
                    :share_code => share.code
                })
            end
        end

        projects
    end

    def get_project_items(
        project_id, 
        upstream)

        project = Project.find_by_id(project_id)
        repo = nil

        if upstream
            repo = GitRepo.new(project.upstream_path)
        else
            repo = GitRepo.new(project.path)
        end

        repo.get_current_tree(project.id)

    end

    def get_project_history(
        project_id,
        upstream)

        project = Project.find_by_id(project_id)
        repo = nil

        if upstream
            repo = GitRepo.new(project.upstream_path)
        else
            repo = GitRepo.new(project.path)
        end

        repo.get_commit_walker()
    end

    

end
