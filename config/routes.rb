Calagator::Application.routes.draw do
  devise_for :users

  match 'omfg' => 'site#omfg'
  match 'hello' => 'site#hello'

  match 'about' => 'site#about'

  match 'opensearch.:format' => 'site#opensearch'

  resources :events do
    collection do
      post :squash_multiple_duplicates
      get :search
      get :duplicates
    end

    member do
      get :clone
    end
  end

  resources :organizations do
    resources :sources do
      collection do
        post :import
      end
    end
  end

  match 'topics/:name' => 'topics#show'
  match 'types/:name' => 'types#show'

  resources :venues do
    collection do
      post :squash_multiple_duplicates
      get :map
      get :duplicates
    end
  end

  resources :versions, :only => [:edit]
  resources :changes, :controller => 'paper_trail_manager/changes'
  match 'recent_changes' => redirect("/changes")
  match 'recent_changes.:format' => redirect("/changes.%{format}")

  match 'export' => 'site#export'
  match 'export.:format' => 'site#export'

  match 'css/:name' => 'site#style'
  match 'css/:name.:format' => 'site#style'

  match '/' => 'site#index', :as => :root

  themes_for_rails

  match '/import_all' => 'sources#import_all'
  match '/:controller(/:action(/:id))'
end
