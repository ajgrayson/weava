class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user

  # we need to make sure the user is logged in by default
  # and make exceptions for what they can access
  before_action :authorize, :verify_profile

  def authorize
    beta = cookies[:beta]
    user = current_user
    
    if beta and not user

      # this sends someone who had previously used a beta access
      # code right to the signin page but still lets them view the
      # home page if they want to. Also leaves the authenticate open.
      if not ['/', '/login', '/auth/authenticate'].include? request.path
        redirect_to '/login'
      end

    elsif not user
      # this is for people without a beta code and prevents them from doing
      # anything other than view the home page and submit their access code
      if not ['/', '/access/WEAVABETA2013'].include? request.path
        if !(beta and request.path == '/login')
          redirect_to '/'
        end
      end
    else 
      if request.path == '/'
        redirect_to '/projects'
      end
    end
  end

  def verify_profile
    user = current_user
    if user
      if not user.name and not ['/setup', '/save_setup', 
        '/auth/logout'].include? request.path

        redirect_to '/setup'
      end
    end
  end

  # Helper to make @user available to views and helpers
  def current_user
    if not @user
      get_current_user()
    end
    @user
  end

  # loads the current user so its available in the views
  private 
    def get_current_user
        if not @user
          if cookies[:sessid]
              users = User.where("session_id = ?", cookies[:sessid])
              if not users.empty?
                @user = users[0]
              end
          end
        end
        @user
    end
end
