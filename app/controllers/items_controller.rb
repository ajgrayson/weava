require 'project_service'

class ItemsController < ApplicationController
    before_filter :init
    before_action :authorize_project

    def init
        @project_service = ProjectService.new
    end

    # Ensure the user should be able to access this project
    def authorize_project
        id = params[:project_id]

        # Only apply this on actions where
        # we're accessing a project directly via
        # the id param
        if id != nil
            @project = @project_service.authorize_project(id, 
                @user.id)
            if not @project
                redirect_to route_project_unauthorized
            end
        end
    end

    def new
        @item ={
            :project_id => @project.id,
            :name => "",
            :content => ""
        }
    end

    def create
        name = params[:name]
        content = params[:content]
        
        # get the repo
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))

        if repo.create_file(@user, name, content)
            redirect_to project_path(@project.id)
        else
            @item = {
                :project_id => @project.id,
                :name => name,
                :content => content,
                :errors => [
                    'An item already exists with that name'
                ]
            }
            render 'new'
        end
    end

    def edit
        id = params[:id]
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        file = repo.get_file(id)

        @item = {
            :id => id,
            :project_id => @project.id,
            :name => file[:name],
            :content => file[:content]
        } 
    end

    def update
        commit = params[:commit]
        message = params[:message]
        content = params[:content]
        id = params[:id]
        
        # get the repo
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        
        if commit == 'Save'
            nid = repo.update_file(@user, id, content, message)

            redirect_to project_item_path(@project.id, nid)
        elsif commit == 'Delete'
            repo.delete_file(@user, id, message)

            redirect_to project_path(@project)
        end
    end
    
    def show
        oid = params[:id]

        view_central = params[:view_central]
        if view_central == "true"
            repo = GitRepo.new(@project_service.get_repo_path(@project.code))
            @central_repo = true
        else
            repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        end

        @item = repo.get_file(oid)
        @item[:project_id] = @project.id
        @history = repo.get_file_history(oid)
    end

    def version
        id = params[:id]
        version_id = params[:vid]
        commit_id = params[:cid]

        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))

        @item = repo.get_file_version(commit_id, version_id)
        @item[:project_id] = @project.id
        @latest_item_id = id
    end


    def conflict

        id = params[:id]
        
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))

        @item = repo.get_file(id)

        @conflict = repo.get_conflict(id)

    end

    def update_conflict

        id = params[:id]
        content = params[:content]

        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))

        repo.resolve_conflict(id, content)

        redirect_to '/projects/' + @project.id.to_s + '/conflicts'

    end



    def route_project_unauthorized
        "/403.html"
    end

end







