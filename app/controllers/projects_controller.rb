require 'securerandom'

class ProjectsController < ApplicationController
    before_action :authorize_project

    # Ensure the user should be able to access this project
    def authorize_project
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
        @projects = Project.where("user_id = ? and owner = ?", @user.id, true)
        @shared_projects = Project.where("user_id = ? AND owner = ?", @user.id, false)
    end

    def show
        view_central = params[:view_central]

        if view_central == "true"
            repo = GitRepo.new(@project.upstream_path)
            @central_repo = true
        else
            repo = GitRepo.new(@project.path)
        end

        @history = repo.get_commit_walker()
        @items = repo.get_current_tree(@project.id)
    end

    def new
        # nothing here... carry on
    end

    def edit
        # nothing here... carry on
    end

    def delete 
        # project = Project.find_by_id(params[:id])
        # debugger
        # project.remove()
        # redirect_to :projects
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

            LogMailer.share_project_email(@project, @user, user, share).deliver
            
            redirect_to project_path(@project), notice: 'Project shared with ' + email
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
                        new_project = Project.new(:name => project.name, :user_id => @user.id, :owner => false, :code => project.code)                        
                        new_project.save

                        repo = GitRepo.new(project.upstream_path)
                        repo.clone_to(new_project.path)
                    end

                    redirect_to projects_path, notice: 'New Project Added'
                else
                    redirect_to projects_path, notice: 'Invalid share'
                end
            else
                redirect_to projects_path, notice: 'Invalid share'
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
            project = Project.new(:name => name, :user_id => @user.id, :owner => true)

            # Since its a new project so we need to tell it to init
            # and generate the code and path fields
            project.init()

            if project.save()
                GitRepo.init_at(project.upstream_path, project.path, @user)

                redirect_to :projects
            else
                render 'new'
            end
        else
            # TODO: better feedback why this failed... async lookup??
            render 'new'
        end
    end

    def update
        project = Project.find_by_id(params[:id])

        if(project.update(params[:project].permit(:name))) 
            redirect_to :projects
        else
            render 'edit'
        end
    end

    def view_diff
        upstream_repo = GitRepo.new(@project.upstream_path)
        @diff = upstream_repo.diff(@project.path)
    end

end
