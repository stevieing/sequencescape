#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class ::Endpoints::TubeFromTubeCreations < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:child, :json => "child", :to => "child")
    belongs_to(:child_purpose, :json => "child_purpose")
    belongs_to(:parent, :json => "parent")
    belongs_to(:user, :json => "user")
  end
end
