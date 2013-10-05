class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user

  # we need to make sure the user is logged in by default
  # and make exceptions for what they can access
  before_action :verify_logged_in
  def verify_logged_in
    beta = cookies[:beta]
    user = get_current_user()
    
    if beta and not user

      # this sends someone who had previously used a beta access
      # code right to the signin page but still lets them view the
      # home page if they want to. Also leaves the authenticate open.
      if not ['/', '/login', '/auth/authenticate'].include? request.path
        redirect_to '/login'
      end
      
    else 

      # this is for people without a beta code and prevents them from doing
      # anything other than view the home page and submit their access code
      if not user
        if not ['/', '/access/WEAVABETA2013'].include? request.path
          if !(beta and request.path == '/login')
            redirect_to '/'
          end
        end
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
