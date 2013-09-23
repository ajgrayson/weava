class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user

  # we need to make sure the user is logged in by default
  # and make exceptions for what they can access
  before_action :verify_logged_in
  def verify_logged_in
    get_current_user()
    if not @current_user
        if not ['/login', '/', '/auth/authenticate'].include? request.path
            redirect_to '/login'
        end
    end
  end

  # loads the current user so its available in the views
  def current_user
    get_current_user()
  end

  private 
    def get_current_user
        if cookies[:user_id]
            @current_user = User.find_by_id(cookies[:user_id])
        end
        return @current_user
    end
end
