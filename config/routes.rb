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
      end
    end
    resources :folders
  end

  # # Project files
  # get 'projects' => 'projects#index'
  # get 'projects/:id/share' => 'projects#share'
  # post 'projects/:id/share' => 'projects#create_share'
  # get 'projects/accept/:code' => 'projects#accept_share'

  # Weava::Application.routes.draw do
  #   resources :items
  # end

  # get 'projects/:id/newfile' => 'projects#new'
  # post 'projects/:id/createfile' => 'projects#createfile'
  # get 'projects/:id/editfile/:oid' => 'projects#editfile'
  # get 'projects/:id/showfile/:oid' => 'projects#showfile'
  # get 'projects/:id/showfileversion/:oid' => 'projects#showfileversion'
  # post 'projects/:id/updatefile/:oid' => 'projects#updatefile'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Weava::Application.routes.draw do
  #   resources :users
  # end

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
