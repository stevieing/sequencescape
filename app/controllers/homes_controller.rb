# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

class HomesController < ApplicationController
  before_action :login_required

  def show
    @links = configatron.fetch(:external_applications, [])
    @pipelines = current_user.pipelines.active
    @latest_batches = current_user.batches.latest_first.limit(10).includes(:pipeline)
    @assigned_batches = current_user.batches.latest_first.where('assignee_id != user_id').limit(10).includes(:pipeline)
    @submissions = current_user.submissions.latest_first.limit(10)
    @studies = current_user.interesting_studies.newest_first.limit(10)
  end
end
