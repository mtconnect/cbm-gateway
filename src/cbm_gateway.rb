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

require 'adapter'
require 'configuration'
require 'sqlite_db'

module CBMGateway
  class CBMAdapter
    def initialize(port = 7979)
      @adapter = MTConnect::Adapter.new(port)
      @connected = false
      # Create and add the data items
      @remaining_useful_life = Hash.new()
      @position_capability = Hash.new()
      @spindle_capability = Hash.new()
      @remaining_useful_delta = Hash.new()
      @nameStorage = []
      @life = Hash.new()
      @spindleCap = Hash.new()
      @posCap = Hash.new()
      @timeChecked = Hash.new()

      @conf = YAML.load_file("#{$config_dir}device_data.yaml")
      @conf.each do |ele|
        #stores values for each device in appropriate hashes, raises error if info is missing
        deviceName = ele[0]
        if(ele[1]['startSpindleCap'].nil? or ele[1]['startRUL'].nil? or ele[1]['startSpindleCap'].nil? or ele[1]['startTime'].nil?)
          raise "Error parsing YAML: Required device information for device #{deviceName} not found"
        end
        #reads data from YAML file
        @nameStorage << deviceName
        @spindleCap[deviceName] = ele[1]['startSpindleCap'].to_f
        @life[deviceName] = ele[1]['startRUL'].to_f
        @posCap[deviceName] = ele[1]['startPosCap'].to_f
        @timeChecked[deviceName] = ele[1]['startTime'].to_s

        #add data items to adapter
        @adapter.data_items << (@remaining_useful_life[deviceName] = MTConnect::Event.new("#{deviceName}:rulr"))
        @adapter.data_items << (@remaining_useful_delta[deviceName] = MTConnect::Event.new("#{deviceName}:ruld"))
        @adapter.data_items << (@position_capability[deviceName] = MTConnect::Event.new("#{deviceName}:cap_position"))
        @adapter.data_items << (@spindle_capability[deviceName] = MTConnect::Event.new("#{deviceName}:cap_rv"))
      end

    end

    def connect
      @adapter.start


      while true
        @adapter.gather do
          @nameStorage.each do |name|
            #calculute change in RUL and use model to update other statistics
            rulDelta, @timeChecked[name] = SQLite_CBM_DB.calculateRULDelta(name,@timeChecked[name])
            @life[name] -= rulDelta
            @spindleCap[name] **= (1-rulDelta/(@life[name]**1.5))
            @posCap[name] **= (1-rulDelta/(@life[name]**1.5))

            #update adapter data items (spindle cap and pos cap are rounded for practicality)
            @remaining_useful_life[name].value = @life[name]
            @remaining_useful_delta[name].value = rulDelta
            @position_capability[name].value = @posCap[name].round
            @spindle_capability[name].value = (@spindleCap[name]).round(-2)

            #update yaml file
            @conf[name]['startRUL'] = @life[name]
            @conf[name]['startPosCap'] = @posCap[name]
            @conf[name]['startSpindleCap'] = @spindleCap[name]
            @conf[name]['startTime'] = @timeChecked[name]

            File.open("#{$config_dir}device_data.yaml",'w') do |h|
              h.write @conf.to_yaml
            end
          end
        end
        sleep 10
      end
    end
  end
end
