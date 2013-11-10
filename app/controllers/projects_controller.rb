require 'securerandom'
require 'email_share_worker'
require 'project_service'
require 'zendesk_service'
require 'open-uri'
require 'net/http'

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
                redirect_to '/403.html?id=' + id
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

    def wiz_select_type
        
    end

    def wiz_enter_details
        type = params[:type]
        @project = Project.new(:project_type => type)

        if type == 'zendesk'
            #render 'wiz_connect_zendesk'
            oauth_uri = URI::encode(Rails.application.config.zendesk_oauth_uri)
            response_type = 'code'
            redirect_uri = URI::encode(Rails.application.config.zendesk_redirect_uri)
            client_id = URI::encode(Rails.application.config.zendesk_client_id)
            scope = URI::encode('read write')
            state = ''

            redirect_to "#{oauth_uri}?response_type=#{response_type}" + 
                "&redirect_uri=#{redirect_uri}&client_id=#{client_id}&scope=#{scope}"
        else
            render 'wiz_new'
        end
    end

    def zendesk_handle_auth_redirect
        code = params[:code]
        error = params[:error]
        error_description = params[:error_description]

        if not error
            grant_type = 'authorization_code'
            client_id = URI::encode(Rails.application.config.zendesk_client_id)
            client_secret = URI::encode(Rails.application.config.zendesk_app_id)
            redirect_uri = URI::encode(
                Rails.application.config.zendesk_redirect_uri)
            scope = URI::encode('read')

            uri = URI(Rails.application.config.zendesk_oauth_token_uri)

            access_token = nil
            Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |https|

                request = Net::HTTP::Post.new(uri.path)
                request.set_form_data(
                        "grant_type" => grant_type,
                        "client_id" => client_id,
                        "client_secret" => client_secret,
                        "redirect_uri" => redirect_uri,
                        "scope" => "read",
                        "code" => code
                    )

                response = https.request(request)
                res = JSON.parse(response.body)
                access_token = res['access_token']
            end

            if access_token != nil
                zd_service = ZendeskService.new(access_token)
                @categories = zd_service.get_project_name()
                # if name
                #     @project_service.create_zendesk_project(@user, name)
                # else
                #     redirect_to route_zendesk_auth_error("API Error", 
                #         "Failed to get project name")
                # end

                render 'categories'

            else
                redirect_to route_zendesk_auth_error("Auth Error", 
                    "Failed to get access token")
            end

        else
            redirect_to route_zendesk_auth_error(error, error_description)
        end
    end

    def zendesk_handle_token_redirect
        
    end

    def auth_error
        @error = params[:error]
        @error_description = params[:error_description]
    end

    def new

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

        shared = @project_service.share_project(@project, email)
        if shared
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

    # Creates a new project and sets up a git repo
    # TODO: make this async...
    def create
        type = params[:project][:project_type]
        if type == 'zendesk'
            domain = params[:domain]
            username = params[:username]
            password = params[:password]
            token = params[:token]

            @project_service.connect_to_zendesk(domain, username, password, token)
            ###
        else
            name = params[:project][:name]

            error = @project_service.create_project(@user, name)
            if not error
                redirect_to route_projects()
            else
                # TODO: better feedback why this failed...
                render 'new'
            end
        end
    end

    def update
        project = Project.find_by_id(params[:id])
        if project.update(params[:project].permit(:name))
            redirect_to route_projects()
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

    def route_zendesk_auth_error(error, error_description) 
        "/projects/auth_error?error=#{error}&error_description=#{error_description}"
    end

end
