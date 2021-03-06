#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module ModelExtensions::Project
  def self.included(base)
    base.class_eval do
      has_many :submissions
      named_scope :include_roles, :include => { :roles => :users }
    end
  end

  def roles_as_json
    Hash[
      self.roles.map do |role|
        [ role.name.underscore, role.users.map { |user| { :login => user.login, :email => user.email, :name => user.name } } ]
      end
    ]
  end
end
