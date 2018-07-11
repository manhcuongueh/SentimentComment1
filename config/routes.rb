Rails.application.routes.draw do
  root 'users#new'
  post '' => 'users#delete'
  get  'index' => 'users#index'
  post 'index' => 'users#create'
  post 'index/write' => 'users#write_excel'
  post 'index/single' => 'users#write_single'
  get  'show'  => 'users#show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
