#
# Cookbook:: chef-splunk
# Libraries:: helpers
#
# Author: Dang H. Nguyen <dang.nguyen@disney.com>
# Copyright:: 2020
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module Splunk
  module Resources
    module Helpers
      require 'iniparse'

      def save_doc(file)
        do_backup(file)
        @document.save(file)
      end

      def do_backup(file = nil)
        require 'chef/util/backup'
        ::Chef::Util::Backup.new(@new_resource, file).backup!
      end

      def remove_option_from_section(option)
        @document[@stanza_title].delete(option)
      end

      def add_new_section
        @document.section(@stanza_title.to_s)
      end

      def remove_section(section)
        @document.delete(section)
      end

      def do_create(options)
        updated = []

        unless @document.has_section?(@stanza_title)
          converge_by("Adding stanza [#{@stanza_title}]") do
            add_new_section
            updated << true if @document.has_section?(@stanza_title)
          end
        end

        case options.class
        when Array
          options.each do |option|
            value = new_resource.send(option)
            if @document[@stanza_title].lines.keys.include?(option) && (value.nil? || !property_is_set?(option.to_sym))
              converge_by("removing #{option} from [#{@stanza_title}]") do
                remove_option_from_section(option)
                updated << true unless @document[@stanza_title].has_option?(option)
              end
            elsif !@document[@stanza_title].has_option?(option) && property_is_set?(option.to_sym)
              converge_by("adding '#{option} = #{value}' in [#{@stanza_title}]") do
                new_value_to_option(option)
                updated << true if @document[@stanza_title].has_option?(option) && value == @document[@stanza_title][option]
              end
            elsif @document[@stanza_title].has_option?(option) && value != @document[@stanza_title][option]
              converge_by("updating '#{option} = #{value}' in [#{@stanza_title}]") do
                new_value_to_option(option)
                updated << true if value == @document[@stanza_title][option]
              end
            end
          end
        when Hash
          options.each do |option, value|
            if @document[@stanza_title].lines.keys.include?(option) && value.nil?
              converge_by("removing #{option} from [#{@stanza_title}]") do
                remove_option_from_section(option)
                updated << true unless @document[@stanza_title].has_option?(option)
              end
            elsif !@document[@stanza_title].has_option?(option)
              converge_by("adding '#{option} = #{value}' in [#{@stanza_title}]") do
                new_value_to_option(option)
                updated << true if @document[@stanza_title].has_option?(option) && value == @document[@stanza_title][option]
              end
            elsif @document[@stanza_title].has_option?(option) && value != @document[@stanza_title][option]
              converge_by("updating '#{option} = #{value}' in [#{@stanza_title}]") do
                new_value_to_option(option)
                updated << true if value == @document[@stanza_title][option]
              end
            end
          end
        end

        if @document[@stanza_title].lines.keys.empty?
          converge_by("removing stanza [#{@stanza_title}]") do
            remove_section(@stanza_title)
            updated << true unless @document.has_section?(@stanza_title)
          end
        end

        updated.any?
      end

      def do_remove
        if @document.has_section?(@stanza_title)
          converge_by("Removing stanza [#{@stanza_title}]") { @document.delete(@stanza_title) }
        end
        !@document.has_section?(@stanza_title)
      end
    end
  end
end
