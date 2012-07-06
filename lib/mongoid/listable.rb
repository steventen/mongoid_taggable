# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
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

module Mongoid::Listable
  def self.included(base)
    # create fields for tags and index it
    base.field :list_array, :type => Array, :default => []
    base.index({list_array: 1}, {drop_dups: true})

    # # add callback to save tags index
    # base.after_save do |document|
    #   if document.list_array_changed
    #     document.class.save_tags_index!
    #     document.list_array_changed = false
    #   end
    # end

    # extend model
    base.extend         ClassMethods
    base.send :include, InstanceMethods
    base.send :attr_accessor, :list_array_changed

  end

  module ClassMethods
    # returns an array of distinct ordered list of tags defined in all documents

    def listed_as(tag)
      self.any_in(:list_array => [tag])
    end

    def listed_as_all(*tags)
      self.all_in(:list_array => tags.flatten)
    end

    def listed_as_any(*tags)
      self.any_in(:list_array => tags.flatten)
    end

    def lists
      lists_index_collection.master.find.to_a.map{ |r| r["_id"] }
    end

    # # retrieve the list of tags with weight (i.e. count), this is useful for
    # # creating tag clouds
    # def tags_with_weight
    #   tags_index_collection.master.find.to_a.map{ |r| [r["_id"], r["value"]] }
    # end

    def lists_separator(separator = nil)
      @lists_separator = separator if separator
      @lists_separator || ','
    end

    def lists_index_collection_name
      "#{collection_name}_lists_index"
    end

    def lists_index_collection
      @@lists_index_collection ||= Mongoid::Collection.new(self, lists_index_collection_name)
    end

  end

  module InstanceMethods
    def lists
      (list_array || []).join(self.class.lists_separator)
    end

    def lists=(lists)
      self.list_array = lists.split(self.class.lists_separator).map(&:strip).reject(&:blank?)
      @list_array_changed = true
    end
  end
end
