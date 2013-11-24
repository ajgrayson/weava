require 'project_role_type'

class ProjectService

    def authorize_project(project_id, user_id)
        return get_project(project_id, user_id)
    end

    def is_configured(project, user)
        upstream = get_repo_path(project.code)
        path = get_repo_path(project.code, user.id)

        if not File.directory?(upstream) or not File.directory?(path)
            return { 
                :error => 'Storage not configured' 
            }
        end

        return {
            :error => nil
        }
    end

    # Get all the user projects including
    # shared projects
    def get_projects_for_user(user_id)
        projects = []

        # get the user
        user = User.find_by_id(user_id)

        # get their projects
        my_projects = Project.joins(:project_roles).where(
            project_roles: {user_id: user_id})

        # read the projects into a hash with all
        # the required details
        if my_projects
            my_projects.each do |project|
                projects.push(get_project_hash(project, user, nil, nil))
            end
        end

        # get all the current projects that have
        # been shared with the user
        shares = ProjectShare.where(
            "user_id = ? and (accepted is " + 
                "null or accepted = false)", user_id)

        shares.each do |share|
            project = Project.find_by_id(share.project_id)
            if project
                projects.push(
                    get_project_hash(project, user, true, share.code))
            end
        end

        projects
    end

    def get_project_items(
        project_code, 
        user_id,
        upstream)

        repo = nil
        if upstream
            repo = GitRepo.new(get_repo_path(project_code))
        else
            repo = GitRepo.new(get_repo_path(project_code, user_id))
        end

        repo.get_current_tree
    end

    def get_project_history(
        project_code,
        user_id,
        upstream)

        repo = nil
        if upstream
            repo = GitRepo.new(get_repo_path(project_code))
        else
            repo = GitRepo.new(get_repo_path(project_code, user_id))
        end

        repo.get_commit_walker()
    end

    def create_project(user, name, type = ProjectType::DEFAULT)
        existing_project = Project.where(name: name, 
            user_id: user.id)

        if not existing_project.any?
            project = Project.create!(
                :name => name,
                :user_id => user.id,
                :project_type => type,
                :code => SecureRandom.uuid)

            ProjectRole.create!(
                :project_id => project.id, 
                :user_id => user.id, 
                :role => ProjectRoleType::Admin)

            GitRepo.init_at(get_repo_path(project.code), 
                get_repo_path(project.code, user.id), user)

            return {
                id: project.id
            }
        else
            return {
                error: 'A project already exists with that name'
            }
        end
    end

    def get_project(id, user_id)
        project = Project.joins(:project_roles).find_by(
            project_roles: { 
                project_id: id, 
                user_id: user_id
            })

        # this is because a join makes the returned project
        # readonly... :(
        if project
            return Project.find_by_id(project.id)
        end
        return nil
    end

    def share_project(project, user_email)
        user = User.find_by email: user_email
        if user
            share = ProjectShare.create!(
                :project_id => project.id, 
                :owner_id => project.user_id, 
                :user_id => user.id, 
                :code => SecureRandom.uuid)

            EmailShareWorker.perform_async(
                project.id, project.user_id, user.id, share.id)

            return share
        else
            return nil
        end
    end

    def accept_share(user, share_code)
        shares = ProjectShare.where("code = ?", share_code)
        if not shares.empty?
            share = shares.first
            if share.user_id == user.id
                # we got a live one bob... what do we do?
                project = Project.find_by_id(share.project_id)

                if project
                    ProjectRole.create!(
                        :project_id => project.id, 
                        :user_id => user.id,
                        :role => ProjectRoleType::Editor)

                    share.update(:accepted => true)

                    repo = GitRepo.new(get_repo_path(project.code))
                    repo.fork_to(get_repo_path(project.code, user.id))

                    return nil
                else
                    return 'Project not found'
                end
            else
                return 'Share not found'
            end
        else
            return 'Share not found'
        end
    end

    def delete_project(project, user)
        if project.user_id == user.id # owner
            FileUtils.rm_rf(get_repo_path(project.code))
            FileUtils.rm_rf(get_repo_path(project.code, user.id))

            if project.project_type == ProjectType::DESK
                desk_service = DeskService.new
                desk_service.delete_project(project.id)
            end

            child_projects = ProjectRole.where(project_id: project.id)
            if child_projects.any?
                child_projects.each do |cp|
                    FileUtils.rm_rf(get_repo_path(project.code, cp.user_id))
                    #cp.destroy
                end
            end

            project.destroy
        end
    end

    def get_repo_path(project_code, user_id = nil)
        if user_id
            user_path = Rails.application.config.git_user_path
            return File.join(user_path, 'user' + user_id.to_s, project_code.to_s)
        else
            core_path = Rails.application.config.git_root_path
            return File.join(core_path, project_code.to_s)
        end
    end

    private 
        def get_project_hash(project, user, pending, share_code)
            project_owner = user

            # if they arent the owner then find
            # the owner
            if project.user_id != user.id
                project_owner = User.find_by_id(project.user_id)
            end

            return {
                :id => project.id,
                :name => project.name,
                :username => project_owner.name,
                :owned => project.user_id == user.id,
                :pending => pending,
                :type => project.project_type,
                :share_code => share_code
            }
        end

end
