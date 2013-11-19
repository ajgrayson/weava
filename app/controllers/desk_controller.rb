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
        if id
            @project = Project.find_by_id(id)
            if not @project or @project.user_id != @user.id
                redirect_to route_project_unauthorized()
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

        redirect_to route_sync('init')
    end

    def sync
        stage = params[:stage]

        if stage == 'init'
            # kick of background task to fetch account details
            job_id = DeskNewProjectWorker.perform_async(
                session[:access_token], session[:access_token_secret], @user.id)

            session[:sync_project_job] = job_id
            session[:sync_project_job_title] = "Initializing Desk Project"
        elsif stage == 'import'
            # kick of background task to fetch account details
            job_id = DeskImportProjectWorker.perform_async(
                @project.id, @user.id)

            session[:sync_project_job] = job_id
            session[:sync_project_job_title] = "Importing Desk Project"
        end

        redirect_to route_sync_progress(stage)
    end

    def sync_progress
        stage = params[:stage]
        job_id = session[:sync_project_job]
        data = Sidekiq::Status::get_all(job_id)

        puts 'sync_progress ' + stage.to_s

        if data['message'] == 'Done'
            if stage == 'init'
                redirect_to route_sync('import', data['project_id'])
            elsif stage == 'import'
                redirect_to project_path(data['project_id'])
            end
        else
            @sync_title = session[:sync_project_job_title]
            @sync_status_message = data['message']
            @sync_progress_value = data['num']
            @sync_stage = stage
        end
    end

    def check_sync_progress
        stage = params[:stage]
        job_id = session[:sync_project_job]
        data = Sidekiq::Status::get_all(job_id)

        puts 'check_sync_progress ' + stage.to_s

        redirect_url = nil
        if stage == 'init'
            redirect_url = route_sync('import', data['project_id'])
        elsif stage == 'import'
            redirect_url = project_path(data['project_id'])
        end

        msg = {
            :status => data['message'], 
            :value => data['num'],
            :redirect_url => redirect_url
        }

        respond_to do |format|
            format.json  {
                render :json => msg
            }
        end
    end


    #
    # Route Helpers
    #

    def route_sync(stage, project_id = nil)
        if not project_id
            "/desk/sync?stage=#{stage}"
        else
            "/desk/#{project_id}/sync?stage=#{stage}"
        end 
    end

    def route_sync_progress(stage, project_id = nil)
        if not project_id
            "/desk/sync_progress?stage=#{stage}"
        else
            "/desk/#{project_id}/sync_progress?stage=#{stage}"
        end
    end

    def route_project_unauthorized
        "/403.html"
    end

end
