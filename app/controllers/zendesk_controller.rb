require 'zendesk_worker'

class ZendeskController < ApplicationController
    before_filter :init
    before_action :authorize_project

    def init(project_service = ProjectService.new, 
        zendesk_service = ZendeskService.new)

        @project_service = project_service
        @zendesk_service = zendesk_service
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
                redirect_to route_project_unauthorized(@project.id)
            end
        end
    end

    # (4) zendesk redirects to here after the user makes a 
    # decision about the oauth request
    def auth_redirect
        code = params[:code]
        error = params[:error]
        error_description = params[:error_description]
        id = params[:state]

        if not error
            # we need to get the access token
            access_token = ZendeskService.get_oauth_access_token(
                code,
                error,
                error_description)

            if access_token != nil
                # if we get one then we want to save it to 
                # the project for use later on
                project = Project.find_by_id(id)
                zd_project = ZendeskProject.create!(
                    :project_id => project.id,
                    :token => access_token)

                redirect_to route_begin_import(project.id)
            else
                redirect_to route_zendesk_auth_error(
                    "Auth Error", 
                    "Failed to get access token")
            end
        else
            redirect_to route_zendesk_auth_error(error, 
                error_description)
        end
    end

    def auth_error
        @error = params[:error]
        @error_description = params[:error_description]
    end

    def begin_import
        # queue up a import in a background worker
        ZendeskWorker.perform_async(
                project.id, project.user_id, user.id, share.id)

        # set the project to sync'ing
        # redirect to sync_progress page

        redirect_to route_sync_progress(@project.id)
    end

    def sync_progress
        @sync_title = "Stuff happening"
        @sync_status_message = "Syncing booboos"
        @sync_progress_value = 50
    end



    #
    # Route Helpers
    #
    def route_projects() 
        '/projects'
    end

    def route_project_unauthorized(project_id)
        '/403.html'
    end

    def route_zendesk_auth_error(error, error_description) 
        "/zendesk/auth_error?error=#{error}" +
            "&error_description=#{error_description}"
    end

    def route_begin_import(project_id)
        "/zendesk/#{project_id}/begin_import"
    end

    def route_sync_progress(project_id)
        "/zendesk/#{project_id}/sync_progress"
    end

end
