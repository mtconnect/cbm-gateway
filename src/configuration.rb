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

require 'yaml'
require 'core_ext'

$config_dir = "#{File.dirname(__FILE__)}/../config/"

if RUBY_PLATFORM =~ /mingw32/
  fn, = Gem.find_files('libxml.rb')
end

$gateway_env ||= ENV['GATEWAY_ENV'] && ENV['GATEWAY_ENV'].to_sym || :production