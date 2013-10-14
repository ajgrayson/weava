class ItemsController < ApplicationController
    before_action :authorize_project

    # Ensure the user should be able to access this project
    def authorize_project
        id = params[:project_id]

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
        repo = GitRepo.new(@project.path)

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
        # "/projects/" + @project.id.to_s + "/updatefile/" + @file[:oid].to_s
        id = params[:id]
        repo = GitRepo.new(@project.path)
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
        repo = GitRepo.new(@project.path)
        
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
        repo = GitRepo.new(@project.path)
        @item = repo.get_file(oid)
        @item[:project_id] = @project.id
        @history = repo.get_file_history(oid)
    end

    def version
        id = params[:id]
        version_id = params[:vid]
        commit_id = params[:cid]

        repo = GitRepo.new(@project.path)

        @item = repo.get_file_version(commit_id, version_id)
        @item[:project_id] = @project.id
        @latest_item_id = id
    end


end
