require 'adapter'
require 'configuration'

module CBMGateway
  class CBMAdapter
    def initialize(port = 7878)
      @adapter = MTConnect::Adapter.new(port)

      @connected = false

      # Create and add the data items
      @adapter.data_items << (@remaining_useful_life = MTConnect::Event.new('rulr'))
      @adapter.data_items << (@position_capability = MTConnect::Event.new('cap_position'))
      @adapter.data_items << (@spindle_capability = MTConnect::Event.new('cap_rv'))
    end

    def connect
      @adapter.start

      # todo - read RUL from agent
      life = 1000
      conf = YAML.load_file("#{$config_dir}deviceRUL.yaml")
      if !conf['startRUL'].nil?
        life = conf['startRUL'].to_i
      end

      while life > 0
        @adapter.gather do
          @remaining_useful_life.value = life
          life -= 10
        end
        sleep 10
      end
    end
  end
end
