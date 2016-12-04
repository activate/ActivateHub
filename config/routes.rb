Rails.application.routes.draw do
  devise_for :users

  resource :user, only: [:show]

  mount RailsAdmin::Engine => '/rails_admin', as: 'rails_admin'

  get 'omfg' => 'site#omfg'
  get 'hello' => 'site#hello'

  get 'about' => 'site#about'

  get 'opensearch.:format' => 'site#opensearch'

  resources :events do
    collection do
      post :squash_many_duplicates
      get :search
      get :duplicates
      get :widget, :action => 'index', :widget => true
      get 'widget/builder', :action => 'widget_builder'
    end

    member do
      get :clone
    end
  end

  resources :organizations do
    resources :sources, except: [:index] do
      collection do
        post :import
      end
    end
  end

  resources :venues do
    collection do
      post :squash_many_duplicates
      get :map
      get :duplicates
    end
  end

  namespace :admin do
    get '/' => :index

    resources :topics, :types

    resources :venues, :events do
      collection do
        get  :duplicates
        post :duplicates, :action => 'squash_many_duplicates'
      end
    end
  end

  resources :versions, :only => [:edit]
  resources :changes, :controller => 'paper_trail_manager/changes'
  get 'recent_changes' => redirect("/changes")
  get 'recent_changes.:format' => redirect("/changes.%{format}")

  get 'css/:name' => 'site#style'
  get 'css/:name.:format' => 'site#style'

  get '/index' => 'site#index'
  get '/index.:format' => 'site#index'

  root :to => "events#index"
end
