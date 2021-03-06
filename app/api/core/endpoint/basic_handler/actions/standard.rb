#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module Core::Endpoint::BasicHandler::Actions::Standard
  def self.extended(base)
    base.class_eval do
      include InstanceMethods

      class_inheritable_reader :standard_actions
      write_inheritable_attribute(:standard_actions, {})
    end
  end

  def standard_action(*names)
    standard_actions.merge!(Hash[names.map { |a| [a.to_sym, a.to_sym] }])
  end

  module InstanceMethods
    def standard_update!(request, _)
      request.update!
    end
    private :standard_update!

    def standard_create!(request, _)
      request.create!
    end
    private :standard_create!
  end
end
