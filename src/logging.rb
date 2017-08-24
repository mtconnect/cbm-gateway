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

require 'logger'
require 'yaml'
require 'core_ext'
require 'configuration'

module Logging
  SIZE_SUFFIX = { 'M' => 1024 * 1024, 'K' => 1024, 'B' => 1 }

  def Logging.directory
    logger
    @directory
  end

  def Logging.logger
    unless @logger
      puts "Configuration directory: #{$config_dir}"
      
      doc = YAML.load_file("#{$config_dir}logging.yaml").deep_symbolize_keys
      config = doc[$gateway_env || :production]
      if config
        max_size = config[:max_size] || '1M'
        if max_size =~ /([0-9]+)([kmb])/i
          max_size = $1.to_i * (SIZE_SUFFIX[$2.upcase] || 1024)
        else
          max_size = 1024 * 1024
        end

        retain = config[:retain] || 5
        @directory = config[:directory] || "#{File.dirname(__FILE__)}/../log/"
        puts "Logging directory: #{@directory}"

        level = (config[:level] && Logger.const_get(config[:level].to_sym)) || Logger::INFO
        puts "Logging file: #{config.inspect}" 

        file = case config[:file]
        when nil
          ($gateway_env == :test) ? STDOUT : "#{@directory}collector.log"
        when 'STDOUT'
          STDOUT
        when 'STDERR'
          STDERR
        else
          "#{@directory}#{config[:file]}"
        end

        @logger = Logger.new(file, retain, max_size)
        @logger.level = level
      else
        @logger = Logger.new(STDOUT)
      end
    end
    @logger
  end

  def Logging.level=(level)
    self.logger.level = level
  end

  def logger
    Logging.logger
  end
end

