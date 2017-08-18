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


require 'rexml/document'

module Probe
  def Probe.parse(xml, instance = nil)
    doc = REXML::Document.new(xml)
    header = doc.elements['//Header']
    if instance.nil? ||  header.attributes['instanceId'] != instance
      doc.each_element("//Device") do |ele|
        puts "Found device: #{ele.attributes['name']}"
      end
      header.attributes['instanceId']
    else
      Logging.logger.debug "Instance is the same, skipping parse"
      instance
    end
  end
end
