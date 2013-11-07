require 'sync_zendesk_worker'

class SyncController < ApplicationController
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
                redirect_to route_project_unauthorized(@project.id)
            end
        end
    end

    def setup
        
    end

    def authorize
        
    end

    def start

        SyncZendeskWorker.perform_async(@project.id, @user.id)

        redirect_to project_path(@project), 
                notice: 'Sync has begun'
    end

end
