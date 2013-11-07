require 'securerandom'
require 'email_share_worker'

class ProjectsController < ApplicationController
    before_action :authorize_project
    before_filter :init

    def init(project_service = ProjectService.new)
         @project_service = project_service
    end

    # Ensure the user should be able to access this project
    def authorize_project()
        id = params[:id]

        # Only apply this on actions where
        # we're accessing a project directly via
        # the id param
        if id
            @project = Project.find_by_id(id)
            if not @project or @project.user_id != @user.id
                redirect_to '/403.html'
            end
        end
    end

    def index
        @projects = @project_service.get_projects_for_user(
            @user.id)
    end

    def show
        view_central = params[:view_central]
        @central_repo = view_central == "true"

        if @project.conflict
            redirect_to route_project_conflicts(@project.id)
        else
            @history = @project_service.get_project_history(
                @project.id, @central_repo)

            @items = @project_service.get_project_items(
                @project.id, @central_repo)
        end
    end

    def new
        # nothing here... carry on
    end

    def edit
        # nothing here... carry on
    end

    def delete
        # TODO add delete for project
    end

    def share
        # nothing here... carry on
    end

    def create_share
        email = params[:email]

        users = User.where("email = ?", email)
        if not users.empty? 
            user = users[0]

            share = ProjectShare.new(
                :project_id => @project.id, 
                :owner_id => @user.id, 
                :user_id => user.id, 
                :code => SecureRandom.uuid)

            share.save

            EmailShareWorker.perform_async(
                @project.id, @user.id, user.id, share.id)

            redirect_to project_path(@project), 
                notice: 'Project shared with ' + email
        else
            @error = 'There are no users with email ' + email
            render 'share'
        end
    end

    def accept_share
        share_code = params[:code]

        if share_code
            shares = ProjectShare.where("code = ?", share_code)
            if not shares.empty?
                share = shares[0]
                if share.user_id == @user.id
                    # we got a live one bob... what do we do?

                    project = Project.find_by_id(share.project_id)

                    if project
                        new_project = Project.new(
                            :name => project.name, 
                            :user_id => @user.id, 
                            :owner => false, 
                            :code => project.code)
                        new_project.save

                        share.update(:accepted => true)

                        repo = GitRepo.new(project.upstream_path)
                        repo.fork_to(new_project.path)
                    end

                    redirect_to projects_path, 
                        notice: 'New Project Added'
                else
                    redirect_to projects_path, 
                        notice: 'Invalid share'
                end
            else
                redirect_to projects_path, 
                    notice: 'Invalid share'
            end
        else
            redirect_to projects_path, notice: 'Invalid share'
        end
    end

    # Creates a new project and sets up a git repo
    # TODO: make this async...
    def create
        name = params[:project][:name]
        
        existingProjects = Project.where('name = ?', name)
        if existingProjects.empty?
            project = Project.new(
                :name => name, 
                :user_id => @user.id, 
                :owner => true)

            # Since its a new project so we need to tell 
            # it to init and generate the code and path fields
            project.init()

            if project.save()
                GitRepo.init_at(project.upstream_path, 
                    project.path, @user)

                redirect_to route_projects()
            else
                render 'new'
            end
        else
            # TODO: better feedback why this failed...
            # async lookup??
            render 'new'
        end
    end

    def update
        project = Project.find_by_id(params[:id])

        if project.update(params[:project].permit(:name))
            redirect_to :projects
        else
            render 'edit'
        end
    end

    def compare
        repo = GitRepo.new(@project.path)
        repo.fetch_origin
        diff = repo.origin_to_local_diff()
        @diff = diff[:diff]
        @patch = diff[:patch]
        @is_fast_forward = repo.is_fast_forward_to_origin()
        @in_sync = repo.in_sync
    end

    def push
        repo = GitRepo.new(@project.path)
        repo.push_to_origin(@user)
        redirect_to project_path(@project)
    end

    def merge
        repo = GitRepo.new(@project.path)
        
        c = repo.merge_from_origin(@user)
        if c == true
            diff = repo.origin_to_local_diff()

            if diff[:diff].length > 0
                redirect_to route_project_compare(@project.id)
            else
                redirect_to project_path(@project)
            end
        else
            @project.update(:conflict => true)
            redirect_to route_project_conflicts(@project.id)
        end
    end

    def conflicts

        repo = GitRepo.new(@project.path)
        @conflicts = repo.get_conflicts

    end

    def undo_merge 
        repo = GitRepo.new(@project.path)
        repo.undo_merge
        @project.update(:conflict => false)
        redirect_to project_path(@project)
    end

    def save_merge
        repo = GitRepo.new(@project.path)
        repo.commit_merge(@user)
        @project.update(:conflict => false)
        redirect_to project_path(@project)
    end

    #
    # Route Helpers
    #
    def route_projects() 
        '/projects'
    end

    def route_project_conflicts(project_id)
        '/projects/' + project_id.to_s + '/conflicts'
    end

    def route_project_compare(project_id)
        '/projects/' + project_id.to_s + '/compare'
    end

    def route_project_unauthorized(project_id)
        '/403.html'
    end

end
