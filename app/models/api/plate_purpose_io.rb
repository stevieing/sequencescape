#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Api::PlatePurposeIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::PlatePurposeIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        alias_method(:json_root, :url_name)
      end
    end

    def url_name
      "plate_purpose"
    end
  end

  renders_model(::PlatePurpose)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
end
