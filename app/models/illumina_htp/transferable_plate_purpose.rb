#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014,2015 Genome Research Ltd.
class IlluminaHtp::TransferablePlatePurpose < IlluminaHtp::FinalPlatePurpose
  include PlatePurpose::Library
  include PlatePurpose::RequestAttachment
  include PlatePurpose::WorksOnLibraryRequests

  write_inheritable_attribute :connect_on, 'qc_complete'
  write_inheritable_attribute :connect_downstream, true
  write_inheritable_attribute :connected_class, IlluminaHtp::Requests::SharedLibraryPrep

  def source_wells_for(wells)
    Well.in_column_major_order.stock_wells_for(wells)
  end

end
