#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.
module Submission::Crossable
  def cross_study_allowed
    assets.any? {|a| a.studies.uniq.count  > 1 }
  end

  def cross_project_allowed
    assets.any? {|a| a.projects.uniq.count > 1 }
  end

  def cross_compatible?
    true
  end
end
