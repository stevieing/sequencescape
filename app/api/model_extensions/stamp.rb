#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
module ModelExtensions::Stamp

  def stamp_details=(details)
    self.stamp_qcables.build(details.map{|d| locate_qcable(d) })
  end

  private

  def locate_qcable(d)
    d['qcable'] = Uuid.find_by_external_id(d['qcable']).resource
    d
  end
end
