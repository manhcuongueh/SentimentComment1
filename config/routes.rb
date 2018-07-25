Rails.application.routes.draw do
  root 'users#new'
  post '' => 'users#delete'
  get  'index' => 'users#index'
  post 'index' => 'users#create'
  get 'index/write' => 'users#write_excel'
  get 'index/single' => 'users#write_single'
  get  'show'  => 'users#show'
  get  'comments' =>  'users#all_comments'
  get  'download' =>  'users#download'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
