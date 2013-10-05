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
  Weava::Application.routes.draw do
     resources :users
  end

  # Users extras
  get 'profile' => 'users#show'

  # Projects
  Weava::Application.routes.draw do
    resources :projects
  end

  # Project files
  get 'projects' => 'projects#index'
  get 'projects/:id/newfile' => 'projects#newfile'
  post 'projects/:id/createfile' => 'projects#createfile'
  get 'projects/:id/editfile/:oid' => 'projects#editfile'
  post 'projects/:id/updatefile/:oid' => 'projects#updatefile'

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
