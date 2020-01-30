Knock::Engine.routes.draw do
  post 'auth_token' => 'auth_token#create'
  post 'auth_token/refresh' => 'auth_token#refresh'
end
