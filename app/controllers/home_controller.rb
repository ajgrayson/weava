class HomeController < ApplicationController
  def index
    
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
end
