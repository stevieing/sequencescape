#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ::Endpoints::Qcables < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:asset,  :json => 'asset')
    belongs_to(:lot,    :json => 'lot')
  end

end
