#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
Given /^an unreleasable lane named "([^"]*)" exists$/ do |name|
  Factory(:lane, :name => name, :external_release => false)
end

Given /^a releasable lane named "([^"]*)" exists$/ do |name|
  Factory(:lane, :name => name, :external_release => true)
end
