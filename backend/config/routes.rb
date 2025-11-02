# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Existing routes...
      
      # Webhook endpoint for RaceResult
      namespace :webhooks do
        post 'rfid', to: 'rfid#create'
      end
    end
  end
  
  # ActionCable mount
  mount ActionCable.server => '/cable'
end