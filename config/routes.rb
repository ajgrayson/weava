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
      get 'confirm_delete'
      # project sharing
      get 'share'
      post 'create_share'

      # project git actions
      get 'compare'
      get 'push'
      get 'merge'
      post 'undo_merge'
      post 'save_merge'
      get 'conflicts'
    end
  end

  # project sharing
  # :code = share.code
  get 'projects/accept/:code' => 'projects#accept_share'

  # new project wizard
  get 'projects/new_project/wiz_select_type' => 'projects#wiz_select_type'
  post 'projects/new_project/wiz_enter_details' => 'projects#wiz_enter_details'
  get 'projects/new_project/auth_error' => 'projects#auth_error'

  # zendesk
  # :id = project_id
  get 'zendesk/:id/begin_import' => 'zendesk#begin_import'
  get 'zendesk/:id/sync_progress' => 'zendesk#sync_progress'
  # oauth redirect
  get 'zendesk_auth' => 'zendesk#auth_redirect'

  # desk.com
  # oauth redirect
  get 'desk/auth_redirect' => 'desk#auth_redirect'
  get 'desk/auth' => 'desk#auth'

  get 'desk/sync' => 'desk#sync'
  get 'desk/:id/sync' => 'desk#sync'

  get 'desk/sync_progress' => 'desk#sync_progress'
  get 'desk/:id/sync_progress' => 'desk#sync_progress'

  get 'desk/check_sync_progress' => 'desk#check_sync_progress'
end
