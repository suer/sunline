Sunline::Application.routes.draw do
  get 'scripts/:guid.sh', controller: 'scripts', action: 'sh'
  resources :scripts

  root 'top#index'

  resources :logs
  post 'scripts/:guid/log', controller: 'logs', action: 'create'
  post 'scripts/archive/:id', controller: 'scripts', action: 'archive', as: :archive_script
  post 'scripts/unarchive/:id', controller: 'scripts', action: 'unarchive', as: :unarchive_script

  devise_for :users, controllers: { omniauth_callbacks: 'authentication' }
  devise_scope :user do
    get 'sign_in', to: 'authentication#login', as: :new_user_session
    post 'sign_out', to: 'authentication#logout', as: :destroy_user_session
  end
  get ':controller/:action', controller: 'authentication'
end
