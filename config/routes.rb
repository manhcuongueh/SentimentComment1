Rails.application.routes.draw do
  root 'users#new'
  get  'index' => 'users#index'
  post 'index' => 'users#create'
  get  'show'  => 'users#show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
