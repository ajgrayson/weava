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
      get 'zendesk_sync'
      post 'zendesk_sync_start'
    end
  end
  get 'projects/new_project/wiz_select_type' => 'projects#wiz_select_type'
  post 'projects/new_project/wiz_enter_details' => 'projects#wiz_enter_details'
  get 'projects/accept/:code' => 'projects#accept_share'
  get 'projects/new_project/auth_error' => 'projects#auth_error'

  # Zendesk auth
  get 'zendesk_auth' => 'projects#zendesk_handle_auth_redirect'
  # get 'zendesk_token' => 'projects#zendesk_handle_token_redirect'

end
