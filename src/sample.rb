# Copyright 2014, System Insights, Inc.
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

require 'rexml/document'
require 'sqlite_db'

module Sample
  class StreamError < StandardError; end

  def Sample.parse(xml, instance, program)
    doc = REXML::Document.new(xml)

    if doc.root.name == 'MTConnectError'
      doc.each_element("//Error") do |err|
        if err
          raise StreamError.new("#{err.attributes['errorCode']}: #{err.content}")
        else
          raise StreamError.new("Unknown error")
        end
      end
    end
    nxt = nil
    count = 0
    header = doc.elements['//Header']
    nxt = header.attributes['nextSequence']

    doc.each_element('//Streams/DeviceStream') do |stream|
      begin
        deviceUUID = stream.attributes['uuid']
        deviceName = stream.attributes['name']
        if deviceUUID == nil or deviceName == nil
          return 0, program
        end
        Logging.logger.debug "Got device stream for device with UUID #{deviceUUID}, name #{deviceName}"
        count = 0
        stream.each_element('//ComponentStream/Events/EquipmentTimer') do |ele|
          val = ele.text
          timestamp = ele.attributes['timestamp']
          eventName = ele.attributes['name']
          case eventName
            when 'powered_time','operating_time','working_time'
              if val == 'UNAVAILABLE'
                Logging.logger.info "Attempted to log #{eventName} interval for device #{deviceName}: information unavailable."
                SQLite_CBM_DB.insert_data(deviceUUID,timestamp,eventName, Random.new.rand * 100.0)
              else
                Logging.logger.info "Logged #{eventName} interval for device #{deviceName}."
                SQLite_CBM_DB.insert_data(deviceUUID,timestamp,eventName,val.to_f)
              end
            else
              Logging.logger.error "Got incompatible event with type #{eventName}: skipping event."
          end
          program
          count += 1
        end
      rescue
        Logging.logger.error "Error parsing device stream: #{$!}#{$!.class.name}"
        Logging.logger.debug $!.backtrace.join("\n")
      end
    end
    Logging.logger.error 'Could not find next sequence id' unless nxt
    return nxt.to_i, count, program
  end


end
