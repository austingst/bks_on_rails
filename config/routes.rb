BksOnRails::Application.routes.draw do

  root 'static_pages#home'

  match '/sign_in', to:'sessions#new', via: 'get'
  match '/sign_out', to:'sessions#destroy', via: 'delete' 
  match '/manual', to: 'static_pages#manual', via: 'get'

  resources :sessions, only: [:new, :create, :destroy]

  # resources :accounts

  # resources :contacts

  resources :staffers do
    resource :account, only: [:new, :create, :edit, :update]
    resource :contact, only: [:new, :create, :edit, :update]
  end

  resources :managers do
    resource :account, only: [:new, :create, :edit, :update]
    resource :contact , only: [:new, :create, :edit, :update] 
  end

  resources :riders do
    resource :account, only: [:new, :create, :edit, :update]
    resource :location, only: [:new, :create, :edit, :update]
    resource :rider_rating, only: [:new, :create, :edit, :update]
    resource :qualification_set, only: [:new, :create, :edit, :update]
    resource :skill_set, only: [:new, :create, :edit, :update]
    resource :equipment_set, only: [:new, :create, :edit, :update]
    resources :assignments
    resources :shifts do
      resources :assignments
    end
    resources :conflicts
  end

  resources :restaurants do
    resource :short_contact_info, only: [:new, :create, :edit, :update]
    resources :managers, only: [:new, :create, :edit, :update, :show, :destroy]
      resource :account, only: [:new, :create, :edit, :update]
        # resource :contact, only: [:new, :create, :edit, :update]
    resource :work_specification, only: [:new, :create, :edit, :update]
    resource :rider_payment_info, only: [:new, :create, :edit, :update]
    resource :agency_payment_info, only: [:new, :create, :edit, :update]
    resource :equipment_set, only: [:new, :create, :edit, :update]
    resources :shifts do
      resources :assignments
    end
  end

  resources :shifts do
    resources :assignments
  end

  get 'shift/hanging' => 'shifts#hanging'
  get 'shift/clone_new' => 'shifts#clone_new' 
  get 'shift/batch_new' => 'shifts#batch_new'
  post 'shift/batch_create' => 'shifts#batch_create'

  get 'shift/batch_edit' => 'shifts#batch_edit'
  post 'shift/batch_edit' => 'shifts#batch_update'

  get 'assignment/batch_edit' => 'assignments#batch_edit'
  post 'assignment/batch_edit' => 'assignments#batch_update'
  
  get 'assignment/batch_edit_uniform' => 'assignments#batch_edit_uniform'
  post 'assignment/batch_edit_uniform' => 'assignments#batch_update_uniform'

  get 'assignment/resolve_obstacles' => 'assignments#request_obstacle_decisions'
  post 'assignment/resolve_obstacles' => 'assignments#resolve_obstacles'
  post 'assignment/batch_reassign' => 'assignments#batch_reassign'

  get "grid/shifts"
  match '/shift_grid', to: 'grid#shifts', via: 'get'
  get "grid/availability"
  match '/availability_grid', to: 'grid#availability', via: 'get'
  post "grid/send_emails" => 'grid#send_emails'

  # get 'assignments/override_conflict'
  # get 'assignments/override_double_booking'

  get 'rider/request_conflicts_preview' => 'riders#request_conflicts_preview'
  get 'rider/request_conflicts' => 'riders#request_conflicts'
  post 'riders/:id/conflicts/batch_clone' => 'conflicts#batch_clone'
  get 'riders/:rider_id/conflicts/batch_new' => 'conflicts#batch_new'
  post 'riders/:rider_id/conflicts/batch_new' => 'conflicts#batch_create'

  
  resources :conflicts





  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

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
