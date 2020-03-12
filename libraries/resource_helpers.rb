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

      def do_remove
        if @document.has_section?(@stanza_title)
          converge_by("Removing stanza [#{@stanza_title}]") { @document.delete(@stanza_title) }
        end
        !@document.has_section?(@stanza_title)
      end
    end
  end
end
