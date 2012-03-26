# $Id: routes.rb 493 2006-10-25 15:57:02Z dchud $

LfRails3::Application.routes.draw do 
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  resources :user
  
  match ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  #match ':controller/:action'
  
  #match 'record/search', :to=>'record#search'
  #match 'record/retrieve', :to=>'record#retrieve'
  match 'user/login', :to=>'user#login'
  match '', :to=>"record#search"
  match 'admin', :controller => 'admin/dashboard', :action => 'index'
  match 'admin/dashboard', :to => 'admin/dashboard#index'
  match 'admin/collection', :controller =>'admin/collection', :action=>'list'
  #resources :admin
  namespace :admin do 
      resources :collection do
        get :autocomplete_collection_name, :on => :collection
        get :autocomplete_collection_alt_name, :on => :collection
        get :autocomplete_collection_conn_type, :on => :collection
      end
     resources :dashboard
     resources :manage_roles
     resources :manage_droits
     resources :collection
     resources :harvest_schedule
     resources :primary_document_types
     resources :document_types
     resources :search_tab_filters
     resources :search_tab_subjects
     resources :search_tabs
     resources :editorials
  end
  match 'admin/:controller(/:action(/:id))(.format)'
  match ':controller(/:action(/:id))(.format)'
  
end
