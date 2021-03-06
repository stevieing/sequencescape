#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014,2015 Genome Research Ltd.
class IlluminaC::LibPcrXpPurpose < PlatePurpose

  include PlatePurpose::RequestAttachment

  write_inheritable_attribute :connect_on, 'qc_complete'
  write_inheritable_attribute :connected_class, IlluminaC::Requests::LibraryRequest
  write_inheritable_attribute :connect_downstream, false

end
