# app/services/rfid/processor_service.rb
# Processes RFID reads: maps chip to bib, creates split time

module Rfid
  class ProcessorService
    def process(event_id:, chip_id:, timestamp:, reader_id:)
      event = Event.find(event_id)
      
      # Step 1: Map chip to bib number
      chip_mapping = ChipMapping.find_by(event: event, chip_id: chip_id)
      
      unless chip_mapping
        Rails.logger.warn("Unknown chip: #{chip_id} for event #{event_id}")
        return OpenStruct.new(persisted?: false, errors: ["Unknown chip: #{chip_id}"])
      end
      
      # Step 2: Find effort (runner's race attempt)
      effort = event.efforts.find_by(bib_number: chip_mapping.bib_number)
      
      unless effort
        Rails.logger.warn("No effort found for bib: #{chip_mapping.bib_number}")
        return OpenStruct.new(persisted?: false, errors: ["No runner with bib #{chip_mapping.bib_number}"])
      end
      
      # Step 3: Determine which split (checkpoint) this is
      split = determine_split(event, reader_id)
      
      unless split
        Rails.logger.warn("Unknown reader: #{reader_id}")
        return OpenStruct.new(persisted?: false, errors: ["Unknown reader: #{reader_id}"])
      end
      
      # Step 4: Check for duplicates (within 10 seconds)
      if duplicate_read?(effort, split, timestamp)
        Rails.logger.info("Duplicate read ignored: #{chip_id} at #{timestamp}")
        return OpenStruct.new(persisted?: false, errors: ["Duplicate read"])
      end
      
      # Step 5: Create split time
      split_time = SplitTime.create!(
        effort: effort,
        split: split,
        absolute_time: timestamp,
        time_from_start: calculate_time_from_start(effort, timestamp),
        data_status: :good,
        stopped_here: false,
        source: 'rfid',
        remarks: "RFID: #{chip_id}"
      )
      
      Rails.logger.info("✓ Created split time: #{effort.full_name} at #{split.base_name}")
      
      OpenStruct.new(
        persisted?: true,
        id: split_time.id,
        event_id: event_id,
        split_time: split_time
      )
    end
    
    private
    
    def determine_split(event, reader_id)
      # Map reader IDs to splits
      # This mapping is configured in ReaderSplitMapping model
      mapping = ReaderSplitMapping.find_by(event: event, reader_id: reader_id)
      mapping&.split
    end
    
    def duplicate_read?(effort, split, timestamp)
      effort.split_times
            .where(split: split)
            .where('absolute_time > ? AND absolute_time < ?', 
                   timestamp - 10.seconds, 
                   timestamp + 10.seconds)
            .exists?
    end
    
    def calculate_time_from_start(effort, timestamp)
      return nil unless effort.actual_start_time
      timestamp - effort.actual_start_time
    end
  end
end