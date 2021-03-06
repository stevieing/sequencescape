#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SetIlluminaPipelinesToOptimumPackingStrategy < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
    set_inheritance_column(nil)

    named_scope :illumina_plate_purposes, { :conditions => {
      :name => (IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS + Pulldown::PlatePurposes::PLATE_PURPOSE_FLOWS).flatten,
    } }
    named_scope :cherrypickable_as_target, { :conditions => { :cherrypickable_target => true } }
  end

  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.cherrypickable_as_target.illumina_plate_purposes.find_each do |purpose|
        purpose.update_attributes!(:cherrypick_strategy => 'Cherrypick::Strategy::Optimum')
      end
    end
  end

  def self.down
    # Do nothing here
  end
end
