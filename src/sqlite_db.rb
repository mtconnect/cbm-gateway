require 'sqlite3'
module SQLite_CBM_DB

  def SQLite_CBM_DB.insert_data(uuid,timestamp,category,value)
    if $database.nil?
      $database = SQLite3::Database.new 'cbm-storage.db'
      $table = $database.execute 'CREATE TABLE IF NOT EXISTS deviceInfo(uuid TEXT, timestamp TEXT, eventCategory TEXT, eventVal FLOAT)'
      $database.execute 'CREATE UNIQUE INDEX IF NOT EXISTS idx_event ON deviceInfo(uuid, timestamp, eventCategory)'
      $database.execute 'CREATE INDEX IF NOT EXISTS idx_uuid ON deviceInfo(uuid)'
#      $database.open
    end

    $database.execute('INSERT INTO deviceInfo VALUES(?,?,?,?)',[uuid,timestamp,category,value])
  rescue
    Logging.logger.error "Error parsing device stream: #{$!}#{$!.class.name}"
    Logging.logger.debug $!.backtrace.join("\n")
  end

end
