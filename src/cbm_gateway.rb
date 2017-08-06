require 'adapter'
require 'configuration'
require 'sqlite_db.rb'

module CBMGateway
  class CBMAdapter
    def initialize(port = 7979)
      @adapter = MTConnect::Adapter.new(port)
      @connected = false
      # Create and add the data items
      @adapter.data_items << (@remaining_useful_life = MTConnect::Event.new('rulr'))
      @adapter.data_items << (@position_capability = MTConnect::Event.new('cap_position'))
      @adapter.data_items << (@spindle_capability = MTConnect::Event.new('cap_rv'))
    end

    def connect
      @adapter.start
      uuidStorage = []
      life = Hash.new()
      spindleCap = Hash.new()
      posCap = Hash.new()
      timeChecked = Hash.new()

      conf = YAML.load_file("#{$config_dir}deviceRUL.yaml")
      conf.each do |ele|
        #stores values for each device in appropriate hashes, raises error if info is missing
        deviceUUID = ele[0]
        if(ele[1]['startSpindleCap'].nil? or ele[1]['startRUL'].nil? or ele[1]['startSpindleCap'].nil? or ele[1]['startTime'].nil?)
          raise "Error parsing YAML: Required device information for device #{deviceUUID} not found"
        end
        uuidStorage << deviceUUID
        spindleCap[deviceUUID] = ele[1]['startSpindleCap'].to_f
        life[deviceUUID] = ele[1]['startRUL'].to_f
        posCap[deviceUUID] = ele[1]['startPosCap'].to_f
        timeChecked[deviceUUID] = ele[1]['startTime'].to_s
      end

      while true
        @adapter.gather do
          uuidStorage.each do |uuid|
            rulDelta, timeChecked[uuid] = SQLite_CBM_DB.calculateRULDelta(uuid,timeChecked[uuid])
            life[uuid] -= rulDelta
            spindleCap[uuid] **(1-rulDelta/life[uuid])
            posCap[uuid] ** (1-rulDelta/(life[uuid]**2))
            @remaining_useful_life.value = life[uuid]
            @position_capability.value = posCap[uuid]
            @spindle_capability.value = spindleCap[uuid]
          end
          sleep 2
        end
        sleep 8
      end
    end
  end
end
