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
provides :splunk_index
unified_mode true
resource_name :splunk_index

# Index names must consist of only numbers, lowercase letters, underscores,
# and hyphens. They cannot begin with an underscore or hyphen, or contain
# the word "kvstore".
property :index_name, kind_of: String, name_property: true, regex: /^[^_-][0-9a-zA-Z_=]+/,
                      coerce: proc { |index| index.gsub(/kvstore/, '') }
property :indexes_conf_path, kind_of: String, regex: %r{^/.*/indexes\.conf$}, desired_state: false, required: true
property :backup, kind_of: [FalseClass, Integer], default: 5, desired_state: false
property :options, kind_of: Hash, default: {}

@document = nil
@stanza_title = nil

action_class do
  include Splunk::Resources::Helpers

  def new_value_to_option(option)
    value = new_resource.options[option]
    @document[@stanza_title][option] = value
  end

  def do_create
    updated = []

    unless @document.has_section?(@stanza_title)
      converge_by("Adding stanza [#{@stanza_title}]") do
        add_new_section
        updated << true if @document.has_section?(@stanza_title)
      end
    end

    new_resource.options.each do |option, value|
      value = value.to_s
      if @document[@stanza_title].lines.keys.include?(option) && value.empty?
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

    if @document[@stanza_title].lines.keys.empty?
      converge_by("removing stanza [#{@stanza_title}]") do
        remove_section(@stanza_title)
        updated << true unless @document.has_section?(@stanza_title)
      end
    end

    updated.any?
  end
end

action :create do
  @document ||= IniParse.parse(::File.read(new_resource.indexes_conf_path))
  @stanza_title = new_resource.index_name
  save_doc(new_resource.indexes_conf_path) if do_create
end

action :remove do
  @document ||= IniParse.parse(::File.read(new_resource.indexes_conf_path))
  @stanza_title = new_resource.index_name.to_s
  save_doc(new_resource.indexes_conf_path) if do_remove
end
