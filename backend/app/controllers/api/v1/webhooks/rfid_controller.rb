# app/controllers/api/v1/webhooks/rfid_controller.rb
# Receives webhook POST from RaceResult when RFID chip is detected
# Processes and broadcasts to mobile apps via ActionCable

module Api
  module V1
    module Webhooks
      class RfidController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :verify_webhook_signature
        
        # POST /api/v1/webhooks/rfid
        def create
          rfid_read = process_rfid_read(webhook_params)
          
          if rfid_read.persisted?
            # Broadcast to WebSocket subscribers
            ActionCable.server.broadcast(
              "event_#{rfid_read.event_id}",
              {
                type: 'split_time_created',
                data: split_time_json(rfid_read.split_time)
              }
            )
            
            render json: { status: 'success', id: rfid_read.id }, status: :created
          else
            render json: { status: 'error', errors: rfid_read.errors }, status: :unprocessable_entity
          end
        end
        
        private
        
        def webhook_params
          params.require(:webhook).permit(
            :event_id,
            :chip_id,
            :timestamp,
            :reader_id,
            :rssi
          )
        end
        
        def verify_webhook_signature
          # Verify webhook authenticity using shared secret
          expected = OpenSSL::HMAC.hexdigest(
            'SHA256',
            ENV['RACERESULT_WEBHOOK_SECRET'],
            request.raw_post
          )
          
          unless Rack::Utils.secure_compare(expected, request.headers['X-RaceResult-Signature'])
            render json: { error: 'Invalid signature' }, status: :unauthorized
          end
        end
        
        def process_rfid_read(params)
          Rfid::ProcessorService.new.process(
            event_id: params[:event_id],
            chip_id: params[:chip_id],
            timestamp: Time.parse(params[:timestamp]),
            reader_id: params[:reader_id]
          )
        end
        
        def split_time_json(split_time)
          {
            id: split_time.id,
            bib_number: split_time.effort.bib_number,
            runner_name: split_time.effort.full_name,
            split_name: split_time.split.base_name,
            absolute_time: split_time.absolute_time,
            time_from_start: split_time.time_from_start,
            source: 'rfid'
          }
        end
      end
    end
  end
end