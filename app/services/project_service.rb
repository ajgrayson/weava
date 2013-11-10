require 'zendesk_api'

class ProjectService

    def authorize_project(project_id, user_id)
        project = Project.find_by_id(project_id)
        if not project or project.user_id != user_id
            nil
        else
            project
        end
    end

    # Get all the user projects including
    # shared projects
    def get_projects_for_user(user_id)

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

    def share_project(project, user_email)
        users = User.where("email = ?", user_email)
        if not users.empty? 
            user = users.first

            share = ProjectShare.new(
                :project_id => project.id, 
                :owner_id => project.user_id, 
                :user_id => user.id, 
                :code => SecureRandom.uuid)

            share.save

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
                    new_project = Project.new(
                        :name => project.name, 
                        :user_id => user.id, 
                        :owner => false, 
                        :code => project.code)
                    new_project.save

                    share.update(:accepted => true)

                    repo = GitRepo.new(project.upstream_path)
                    repo.fork_to(new_project.path)

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

    def create_zendesk_project(user, name) 
        create_project(user, name, 'zendesk')
    end

    def create_project(user, name, type = 'default')
        existing_projects = Project.where('name = ?', name)
        if existing_projects.empty?
            project = Project.new(
                :name => name,
                :user_id => user.id,
                :project_type => type,
                :owner => true)

            # Since its a new project so we need to tell 
            # it to init and generate the code and path fields
            project.init
            project.save

            GitRepo.init_at(project.upstream_path, 
                project.path, user)

            return nil
        else
            return 'A project already exists with that name'
        end
    end

    def delete_project(project, user)
        if project.user_id == user.id

            if project.owner
                # if they are the owner and there are no forks
                # then we can delete the upstream repo
                child_projects = Project.where("code = ?", 
                    project.code)

                if child_projects.empty?
                    # delete the upstream repo
                    FileUtils.rm_rf(project.upstream_path)
                end
            end

            # delete the cloned repo
            FileUtils.rm_rf(project.path)

            # destroy the db record
            project.destroy

            return true
        end
        return false
    end


end
