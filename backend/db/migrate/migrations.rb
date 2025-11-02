# db/migrate/YYYYMMDDHHMMSS_create_chip_mappings.rb

class CreateChipMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :chip_mappings do |t|
      t.references :event, null: false, foreign_key: true
      t.string :chip_id, null: false
      t.string :bib_number, null: false
      t.timestamps
    end
    
    add_index :chip_mappings, [:event_id, :chip_id], unique: true
    add_index :chip_mappings, [:event_id, :bib_number]
  end
end

# db/migrate/YYYYMMDDHHMMSS_create_reader_split_mappings.rb

class CreateReaderSplitMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :reader_split_mappings do |t|
      t.references :event, null: false, foreign_key: true
      t.references :split, null: false, foreign_key: true
      t.string :reader_id, null: false
      t.timestamps
    end
    
    add_index :reader_split_mappings, [:event_id, :reader_id], unique: true
  end
end

# db/migrate/YYYYMMDDHHMMSS_add_source_to_split_times.rb

class AddSourceToSplitTimes < ActiveRecord::Migration[7.0]
  def change
    add_column :split_times, :source, :string, default: 'manual'
    add_column :split_times, :remarks, :text
    
    add_index :split_times, :source
  end
end