class FoldersController < ApplicationController
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
        @project = Project.find_by_id(params[:project_id])
        @folder ={
            :project_id => @project.id,
            :name => "",
            :parent_id => nil
        }
    end
    
    def create
        name = params[:name]
        parent_id = params[:parent_id]
        
        # get the repo
        repo = GitRepo.new(@project.path)
        if repo.create_folder(@user, name)
            redirect_to project_path(@project.id)
        else
            @folder = {
                :project_id => @project.id,
                :name => name,
                :parent_id => parent_id,
                :errors => [
                    'Not implemented yet.'
                ]
            }

            render 'new'
        end
    end

    def show
        id = params[:id]
        repo = GitRepo.new(@project.path)
        @folder = repo.get_folder(id)
    end
end
