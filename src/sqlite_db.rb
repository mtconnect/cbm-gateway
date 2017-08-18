# Copyright 2017, System Insights, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require 'sqlite3'
module SQLite_CBM_DB

  def SQLite_CBM_DB.init_db
    #makes new database and tables
    dir = File.expand_path(File.dirname(__FILE__) + '/../db')
    $database = SQLite3::Database.new dir + '/cbm-storage.db'
    $table = $database.execute 'CREATE TABLE IF NOT EXISTS deviceInfo(name TEXT, timestamp TEXT, eventCategory TEXT, eventVal FLOAT)'
    $database.execute 'CREATE UNIQUE INDEX IF NOT EXISTS idx_event ON deviceInfo(name, timestamp, eventCategory)'
    $database.execute 'CREATE INDEX IF NOT EXISTS idx_name ON deviceInfo(name)'
    $database.results_as_hash = true
  end

  def SQLite_CBM_DB.insert_data(name, timestamp, category, value)
    if $database.nil?
      SQLite_CBM_DB.init_db
    end
#insert data
    $database.execute('INSERT INTO deviceInfo VALUES(?,?,?,?)',[name,timestamp,category,value])
  rescue
    Logging.logger.warn "Error inserting data: #{$!}"
  end

  def SQLite_CBM_DB.calculateRULDelta(name, time)
    if $database.nil?
      SQLite_CBM_DB.init_db
    end
    rows = $database.execute('SELECT timestamp, eventCategory, eventVal FROM deviceInfo WHERE timestamp > ? AND name = ?', [time,name])
    total = 0.0
    rows.each do |row|
      # each type of event affects the working RUL differently
      # accounts for the fact that powered state will be recorded while working or operating
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
