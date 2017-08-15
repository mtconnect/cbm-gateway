require 'sqlite3'
module SQLite_CBM_DB

  def SQLite_CBM_DB.init_db
    dir = File.expand_path(File.dirname(__FILE__) + '/../db')
    $database = SQLite3::Database.new dir + '/cbm-storage.db'
    $table = $database.execute 'CREATE TABLE IF NOT EXISTS deviceInfo(name TEXT, timestamp TEXT, eventCategory TEXT, eventVal FLOAT)'
    $database.execute 'CREATE UNIQUE INDEX IF NOT EXISTS idx_event ON deviceInfo(name, timestamp, eventCategory)'
    $database.execute 'CREATE INDEX IF NOT EXISTS idx_name ON deviceInfo(name)'
    $database.results_as_hash = true
  end

  def SQLite_CBM_DB.insert_data(name, timestamp, category, value)
#   Initializes database and tables if they doesn't yet exist.
    if $database.nil?
      SQLite_CBM_DB.init_db
    end
    if value == 0
      value = rand*10
    end
    $database.execute('INSERT INTO deviceInfo VALUES(?,?,?,?)',[name,timestamp,category,value])
  rescue
    Logging.logger.error "Error parsing device stream: #{$!}#{$!.class.name}"
    Logging.logger.debug $!.backtrace.join("\n")
  end

  def SQLite_CBM_DB.calculateRULDelta(name, time)
    if $database.nil?
      SQLite_CBM_DB.init_db
    end
    rows = $database.execute('SELECT timestamp, eventCategory, eventVal FROM deviceInfo WHERE timestamp > ? AND name = ?', [time,name])
    total = 0.0
    rows.each do |row|
      # each type of event affects the working RUL differently
      case row['eventCategory']
        when 'powered_time'
          total += row['eventVal'] * 0.001
        when 'operating_time'
          total += row['eventVal'] * 0.399
        when 'working_time'
          total += row['eventVal'] * 0.999
      end
      if row['timestamp'] > time
        time = row['timestamp']
      end
    end
    return total, time
  end

end
