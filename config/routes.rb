Rails.application.routes.draw do
  root 'users#new'
  post '' => 'users#delete'
  get  'index' => 'users#index'
  post 'index' => 'users#create'
  get 'index/write' => 'users#write_excel'
  get 'index/single' => 'users#write_single'
  get  'show'  => 'users#show'
  get  'download' =>  'users#download'
  get  'comments' =>  'comments#comments'
  get  'top-fans' => 'comments#topComments'
  get  'highest-score-users' => 'comments#highestScore'
  get  'lowest-score-users' => 'comments#lowestScore'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
