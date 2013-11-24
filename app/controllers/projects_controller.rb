require 'securerandom'
require 'email_share_worker'
require 'project_service'
require 'zendesk_service'

class ProjectsController < ApplicationController
    before_filter :init
    before_action :authorize_project

    def init(project_service = ProjectService.new)
         @project_service = project_service
    end

    # Ensure the user should be able to access this project
    def authorize_project()
        id = params[:id]

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

    def index
        @projects = @project_service.get_projects_for_user(
            @user.id)
    end

    def show
        if @project
            res = @project_service.is_configured(@project, @user)
            if not res[:error]
                view_central = params[:view_central]
                @central_repo = view_central == "true"

                if @project.project_type == 'zendesk'
                    @zendesk_project = ZendeskProject.where(
                        "project_id = ?", @project.id)
                elsif @project.project_type == 'desk'
                    @desk_project = DeskProject.where(
                        "project_id = ?", @project.id)
                end

                if @project.conflict
                    redirect_to route_project_conflicts(@project.id)
                else
                    @history = @project_service.get_project_history(
                        @project.code, @user.id, @central_repo)

                    @items = @project_service.get_project_items(
                        @project.code, @user.id, @central_repo)
                end
            else
                redirect_to route_project_edit_path(@project.id),
                    :notice => res[:error]
            end
        else
            redirect_to route_project_unauthorized
        end
    end

    # (1) entry point for creating a new project
    def wiz_select_type
        
    end

    # (2) second stage of creating a new project
    # - enter the name of the project
    def wiz_enter_details
        type = params[:type]
        @project = Project.new(:project_type => type)

        if type == 'desk'
            # oauth starts here
            redirect_to route_desk_auth()
        elsif type == 'zendesk'
            render 'wiz_new_zendesk'
        else
            render 'wiz_new_default'
        end
    end

    # (3) third stage of creating a new project
    # save it to the database
    def create
        type = params[:project][:project_type]
        name = params[:project][:name]

        res = @project_service.create_project(
            @user, name, type)

        if res[:error] == nil
            @project = @project_service.get_project(
                res[:id], @user.id)

            if type == 'zendesk'
                redirect_to ZendeskService.oauth_url(res[:id])
                # this will redirect back to 
                #    zendesk_auth => zendesk_handle_auth_redirect
            else
                redirect_to project_path(@project.id),
                    :notice => 'Project created'
            end
        else
            flash.now[:notice] = res[:error]
            if type == 'zendesk'
                render 'wiz_new_zendesk'
            else
                render 'wiz_new_default'
            end
        end
    end


    # def new
    # end

    def edit
        if not @project
            redirect_to route_project_unauthorized
        end
    end

    def destroy
        if @project
            @project_service.delete_project(@project, @user)
            redirect_to route_projects
        else
            redirect_to route_project_unauthorized
        end
    end

    def confirm_delete
        if not @project
            redirect_to route_project_unauthorized
        end
    end

    def share
        if not @project
            redirect_to route_project_unauthorized
        end
    end

    def create_share
        if @project
            email = params[:email]

            shared = @project_service.share_project(@project, email)
            if shared
                redirect_to project_path(@project), 
                    notice: 'Project shared with ' + email
            else
                @error = 'There are no users with email ' + email
                render 'share'
            end
        else
            redirect_to route_project_unauthorized
        end
    end

    def accept_share
        share_code = params[:code]
        if share_code
            error = @project_service.accept_share(@user, 
                share_code)

            if not error
                redirect_to projects_path, 
                    notice: 'New Project Added'
            else
                redirect_to projects_path, 
                    notice: error
            end
        else
            redirect_to '/404.html'
        end
    end

    def update
        if @project
            if @project.update(params[:project].permit(:name))
                redirect_to project_path(@project.id)
            else
                flash.now[:notice] = 'Update failed'
                render 'edit'
            end
        else
            redirect_to route_project_unauthorized
        end
    end

    # def zendesk_sync

    # end

    # def zendesk_sync_start
    #     zd_service = ZendeskService.new
    #     @categories = zd_service.get_categories(@project.id)
    # end

    def compare
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        repo.fetch_origin
        diff = repo.origin_to_local_diff()
        @diff = diff[:diff]
        @patch = diff[:patch]
        @is_fast_forward = repo.is_fast_forward_to_origin()
        @in_sync = repo.in_sync
    end

    def push
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        repo.push_to_origin(@user)
        redirect_to project_path(@project)
    end

    def merge
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        
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

        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        @conflicts = repo.get_conflicts

    end

    def undo_merge 
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        repo.undo_merge
        @project.update(:conflict => false)
        redirect_to project_path(@project)
    end

    def save_merge
        repo = GitRepo.new(@project_service.get_repo_path(@project.code, @user.id))
        repo.commit_merge(@user)
        @project.update(:conflict => false)
        redirect_to project_path(@project)
    end

    #
    # Route Helpers
    #
    def route_projects() 
        "/projects"
    end

    def route_project_conflicts(project_id)
        "/projects/#{project_id}/conflicts"
    end

    def route_project_compare(project_id)
        "/projects/#{project_id}/compare"
    end

    def route_project_edit_path(project_id)
        "/projects/#{project_id}/edit"
    end

    def route_project_unauthorized
        "/403.html"
    end

    def route_desk_auth
        "/desk/auth"
    end

    def route_project_path(project_id)
        "/projects/#{project_id}/show"
    end

end
