#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
budget_divisions = ["Unallocated", "Pathogen (including malaria)", "Human variation"]

budget_divisions.each do |name|
  BudgetDivision.create!(:name => name)
end
