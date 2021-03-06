#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class StripOffUnwantedInputFieldInfos < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_each(:conditions=>'submission_parameters LIKE("%input_field_infos%") AND superceded_by_id = -1') do |st|
        next if excluded?(st)
        sp = st.submission_parameters
        ifi = sp.delete(:input_field_infos)
        st.submission_parameters = sp
        st.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_each(:conditions=>'superceded_by_id = -1') do |st|
        next if excluded?(st)
        sp = st.submission_parameters
        sp[:input_field_infos] = st.new_order.input_field_infos
        st.submission_parameters = sp
        st.save!
      end
    end
  end

  def self.excluded?(submission_template)
    [
      'Cherrypick','Cherrypick for Fluidigm'
    ].include?(submission_template.name)
  end
end
