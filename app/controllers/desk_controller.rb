require "oauth/consumer"
require "desk/desk_api_client"

class DeskController < ApplicationController
    before_filter :init
    before_action :authorize_project

    def init(project_service = ProjectService.new, 
        desk_service = DeskService.new)

        @project_service = project_service
        @desk_service = desk_service
    end

    # Ensure the user should be able to access this project
    def authorize_project
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

    def auth
        desk_client = DeskApiClient.new
        request_token = desk_client.get_request_token

        session[:request_token] = request_token.token
        session[:request_token_secret] = request_token.secret

        redirect_to request_token.authorize_url
    end

    def auth_redirect
        oauth_token = params[:oauth_token]
        oauth_verifier = params[:oauth_verifier]

        desk_client = DeskApiClient.new
        access_token = desk_client.get_access_token(
           oauth_verifier,
           session[:request_token],
           session[:request_token_secret]
        )

        session[:access_token] = access_token.token
        session[:access_token_secret] = access_token.secret

        # desk_client = DeskApiClient.new(
        #     access_token.token, access_token.secret)

        # debugger

        # test = 1

        # job_id = DeskNewProjectWorker.perform_async(
        #     session[:access_token], session[:access_token_secret],
        #     @user.id)

        work = DeskNewProjectWorker.new
        work.perform(session[:access_token], session[:access_token_secret], @user.id)

        redirect_to route_projects #route_sync(job_id)
    end

    def sync
        @job_id = params[:job_id]

        if Sidekiq::Status::complete? @job_id
            redirect_to project_path(data['project_id'])
        else
            data = Sidekiq::Status::get_all(@job_id)
            @sync_status_message = data['message']
            @sync_progress_value = data['num']
        end
    end

    def check_sync_progress
        job_id = params[:job_id]
        data = Sidekiq::Status::get_all(job_id)

        if Sidekiq::Status::complete? job_id
            project_id = Sidekiq::Status::get job_id, :project_id
            msg = {
                :redirect_url => project_path(project_id)
            }
        else
            msg = {
                :status => data['message'], 
                :value => data['num']
            }
        end

        respond_to do |format|
            format.json  {
                render :json => msg
            }
        end
    end

    #
    # Route Helpers
    #

    def route_sync(job_id)
        "/desk/sync?job_id=#{job_id}"
    end

    def route_project_unauthorized
        "/403.html"
    end

    def route_projects
        "/projects"
    end

end
