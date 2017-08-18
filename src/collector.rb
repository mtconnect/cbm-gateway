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

require 'net/http'
require 'rexml/document'
require 'long_pull'
require 'probe'
require 'sample'
require 'thread'


class Collector
  attr_reader :url, :instance, :name
  attr_accessor :next

  include Logging
  @@mutex = Mutex.new
  @@queue = Queue.new
  @@condition = ConditionVariable.new
  @@singleton = nil

  class ParseError < StandardError; end

  def initialize(name, url, filter, device)
    @name, @url, @device = name, url, device
    @filter = "path=#{filter}" if filter
    @instance = @next = nil
    @program = 'unknown'
    @@singleton = self
  end

  def http_client
    dest = URI.parse(@url)
    path = dest.path
    path += '/' unless path[-1] == ?/
    http = Net::HTTP.new(dest.host, dest.port)
    http.open_timeout = 30
    http.read_timeout = 20
    [http, path, @device]
  end

  def initialize_stream(client, path)
    inst = probe(client, path, instance)
    if inst != @instance
      @program = 'unknown' unless @program
      get_current(client, path)
      @instance = inst
    end
  end

  def probe(client, path, instance = nil)
    response = client.get("#{path}probe")

    if response.code == "200"
      @@mutex.synchronize do
        Probe.parse(response.body, instance)
      end
    else
      logger.warn "Get for #{@url} returned result #{response.code}"
      nil
    end

  rescue StandardError => e
    logger.error "#{@name} Error occurred during probe: #{e}"
    logger.debug $!.backtrace.join("\n")
    nil
  end

  # Returns the next sequence number from device.
  def get_current(client, path)
    filter = "?#{@filter}" if @filter
    resp = client.get("#{path}current#{filter}")
    if resp.code == "200"
      @@queue << [resp.body, self]
      @@mutex.synchronize do
        @@condition.wait(@@mutex, 2)
      end
      unless @next
        logger.error "Couldn't get next"
        remove_recovery
        raise ParseError.new("Async parse error")
      end
      logger.debug "#{@name} Current returned #{@next}"
    else
      logger.warn "Get for #{@url} returned result #{resp.code}"
    end
  end
  
  def self.get_asset(asset_id)
    unless @@singleton.nil?
      @@singleton.get_asset(asset_id)
    else
      logger.error "There is no singleton object"
    end
  end
  
  def get_asset(asset_id)
    http, path, device = http_client
    resp = http.get("#{path}asset/#{asset_id}")  
    if resp.code == '200'
      resp.body
    else
      logger.error "Could not get asset: #{asset_id} – #{resp.code}"
      nil
    end
  end

  def self.post_asset(uuid, type, data)
    unless @@singleton.nil?
      @@singleton.post_asset(uuid, type, data)
    else
      logger.error "There is no singleton object"
    end
  end

  def post_asset(uuid, type, data)
    http, path, dev = http_client
    resp = http.post("#{path}asset/#{uuid}?type=#{type}&device=#{dev}", data, { 'ContentType' => 'text/xml' })
    if resp.code == '200'
      logger.info "post returned: #{resp.body}"
    else
      logger.error "Could not post asset: #{asset_id} – #{resp.code}"
      nil
    end
  end
                                           
  def recovery_filename
    dest = URI.parse(@url)
    "#{Logging.directory}Recover_#{name}_#{dest.host.gsub('.', '_')}_#{dest.port}.dat"
  end

  def read_recovery
    @instance = @next = nil
    text = nil
    if File.exist?(recovery_filename)
      File.open(recovery_filename, "r") do |f|
        text = f.read
      end
      @instance, nxt, program = text.split if text
      @instance = @next = nil if @instance.empty?
      @next = nxt.to_i if nxt
      @program = program if program
      logger.info "#{@name} Recovering from #{@next} with instance #{@instance}" if instance
    else
      logger.info "No recovery file found, restarting"
    end

  rescue StandardError => e
    logger.warn "Read error: #{e}"
  end

  def write_recovery
    File.open(recovery_filename, "w") do |f|
      f.write("#{@instance} #{@next} #{@program}")
    end
  rescue StandardError => e
    logger.error "Write error: #{e}"
  end

  def remove_recovery
    File.unlink recovery_filename
  end


  def stream
    logger.info "Starting collecting data for #{@name} from #{@url}"
    read_recovery
    while $running
      begin
        logger.info "Connecting to agent: #{@name} from #{@url}"
        client, path, device = http_client
        path = "#{path}#{device}/"
        initialize_stream(client, path)
        if @instance
          filter = "&#{@filter}" if @filter
          path << "sample?from=#{@next}&frequency=500&count=1000#{filter}"
          logger.info "Requesting: #{path} for #{@name} "

          puller = LongPull.new(client)
          puller.long_pull(path) do |xml|
            return unless $running
            if xml.index("<MTConnectStreams").nil?
              raise ParseError.new("Streams were not found")
            end
            @@queue << [xml, self]
          end
        end

      rescue LongPull::NoBoundary, ParseError
        logger.warn "Received error from stream: #{$!}"
        logger.warn "Resetting instance and next"
        remove_recovery
        @instance = @next = nil
        @program = 'unknown'

      rescue  StandardError => e
        # Just keep retrying. This is usually indicative of a connection problem.
        # Should clean up and only retry connection errors.
        logger.error "#{@name}: An error occurred: #{e.to_s}"
        logger.debug e.backtrace.join("\n")

      rescue Exception => e
        logger.error "#{@name}: An unknown error occurred: #{e.to_s}"
        logger.debug e.backtrace.join("\n")
      end
      client.finish rescue puts $!
      logger.info "#{@name} Disconnected, retrying in 10 seconds"
      sleep 10
    end
    
  ensure
    logger.info "Exiting stream for #{@name}"
  end

  def parse_sample(xml)
    @@mutex.synchronize do
      count = 0
      start = Time.now
      last = @next
      logger.debug "Device: #{@name} (#{@url}) Sequence: #{@next} Instance: #{@instance}"
      nxt, count, @program = Sample.parse(xml, @instance, @program)
      @program = 'unknown' unless @program
      if @next.nil? or nxt > @next
        @next = nxt
        dt = Time.now - start
        dt = 0.00000001 if dt == 0.0
        logger.info "Device: #{@name} (#{@url}) Time to parse: #{dt} (processed #{count} at #{(count/dt).to_i} events/second) - QL: #{@@queue.length}"
        write_recovery
      else
        if nxt < @next
          logger.info "#{@name} (#{@url}) Recovering previous document at {nxt}# currently at #{@next}"
        end
      end
    true
    end

  rescue Sample::StreamError => e
    logger.error "#{@name}: A stream error occurred while parsing: #{e}"
    logger.error e.to_s
    logger.error e.backtrace.join("\n")
    false
    
  rescue StandardError => e
    logger.error "#{@name}: An error occurred while parsing: #{e}"
    logger.error e.to_s
    logger.error e.backtrace.join("\n")
    false

  rescue Exception => e
    logger.error "#{@name}: An unknown exception was through while parsing xml"
    logger.error e.to_s
    logger.error e.backtrace.join("\n")
    false
    
  ensure
    @@condition.signal
  end

  def self.sample_queue
    while $running
      begin
        while $running
          xml, obj = @@queue.pop
          if xml and obj
            unless obj.parse_sample(xml) 
              # If it was unsuccessful, requeue this doc           
              @@queue << [xml, obj]
              break
            end
          end
        end
      rescue
        Logging.logger.error "Error processing from queue: #{$!}"
      end
    end
    
  ensure
    Logging.logger.info "Exiting stream queue thread"  
  end
  
  def self.signal_queue
    @@queue << [nil, nil]
  end
end

