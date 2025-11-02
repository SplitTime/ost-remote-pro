# app/channels/event_channel.rb
# WebSocket channel for real-time event updates
# Mobile apps subscribe to this to receive split time updates

class EventChannel < ApplicationCable::Channel
  def subscribed
    event = Event.find(params[:event_id])
    
    # Verify user has access to this event
    reject unless can_access_event?(event)
    
    stream_from "event_#{event.id}"
    
    Rails.logger.info("Client subscribed to event #{event.id}")
  end
  
  def unsubscribed
    Rails.logger.info("Client unsubscribed")
    stop_all_streams
  end
  
  private
  
  def can_access_event?(event)
    # Check if user is authorized (implement based on your auth)
    # For now, allow all authenticated users
    current_user.present?
  end
end