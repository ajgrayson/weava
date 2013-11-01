Weava::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Site root
  root 'home#index'

  # Main
  get 'access/:code' => 'home#access'

  # Auth
  get 'login' => 'auth#login'
  get 'logout' => 'auth#logout'
  post 'auth/logout' => 'auth#logout'
  post 'auth/authenticate' => 'auth#authenticate'
  
  # Users
  resources :users

  # Users extras
  get 'profile' => 'users#show'
  get 'setup' => 'users#setup'
  post 'save_setup' => 'users#save_setup'

  # Projects
  resources :projects do
    resources :items do
      member do 
        get 'version'
        get 'conflict'
        post 'update_conflict'
      end
    end
    member do
      get 'share'
      post 'create_share'
      get 'compare'
      get 'push'
      get 'merge'
      post 'undo_merge'
      post 'save_merge'
      get 'conflicts'
      get 'setup_sync' => 'sync#setup'
      post 'start_sync' => 'sync#start'
    end
  end
  get 'projects/accept/:code' => 'projects#accept_share'

end
