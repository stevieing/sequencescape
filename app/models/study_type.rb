#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class StudyType < ActiveRecord::Base
  extend Attributable::Association::Target

  has_many :study

  validates_presence_of  :name
  validates_uniqueness_of :name, :message => "of study type already present in database"


  def for_select_dropdown
    valid_for_creation? ? [self.name, self.id] : nil
  end

  def self.include?(studytype_name)
    study_type = StudyType.find_by_name(studytype_name)
    unless study_type.nil?
      return study_type.valid_type
    end
    return false
  end

  module Associations
    def self.included(base)
      base.validates_presence_of :study_type_id
      base.belongs_to :study_type
    end
  end
end
