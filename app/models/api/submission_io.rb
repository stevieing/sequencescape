#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Api::SubmissionIO < Api::Base
  renders_model(::Submission)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:message)

  with_association(:user) do
    map_attribute_to_json_attribute(:login  , 'created_by')
  end

  self.related_resources = [:orders]

  # Quick fix for the warehouse
  with_association(:order) do
    with_association(:project) do
      map_attribute_to_json_attribute(:uuid  , 'project_uuid')
      map_attribute_to_json_attribute(:id  , 'project_internal_id')
      map_attribute_to_json_attribute(:name  , 'project_name')
    end

    with_association(:study) do
      map_attribute_to_json_attribute(:uuid  , 'study_uuid')
      map_attribute_to_json_attribute(:id  , 'study_internal_id')
      map_attribute_to_json_attribute(:name  , 'study_name')
    end
  end
end
