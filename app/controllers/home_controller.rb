class HomeController < ApplicationController
  def index
    if not @user
      render :layout => 'anonymous_home_layout'
    end
  end

  def access
    code = params[:code]  
    
    if(!code)
        redirect_to :home
    else
        if code == 'WEAVABETA2013'
            cookies[:beta] = true
            redirect_to '/login'
        end
    end
  end

  def terms 
    
  end

  def privacy
    
  end
end
