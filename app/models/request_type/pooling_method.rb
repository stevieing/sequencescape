#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class RequestType::PoolingMethod < ActiveRecord::Base

  has_many :request_types
  validates_presence_of :pooling_behaviour
  serialize :pooling_options

  set_table_name('pooling_methods')

  def after_initialize
    import_behaviour
  end

  def import_behaviour
    return if pooling_behaviour.nil?
    behavior_module = "RequestType::PoolingMethod::#{pooling_behaviour}".constantize
    self.class_eval do
      include(behavior_module)
    end
  end

  def pooling_behaviour=(*params)
    super
    import_behaviour
  end

end
