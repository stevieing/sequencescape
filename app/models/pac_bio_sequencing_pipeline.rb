#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class PacBioSequencingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission

  INBOX_PARTIAL               = 'pac_bio_sequencing_inbox'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def inbox_partial
    INBOX_PARTIAL
  end

  # PacBio pipelines do not require their batches to record the position of their requests.
  def requires_position?
    false
  end

  def post_release_batch(batch, user)
    batch.requests.each(&:transfer_aliquots)
  end

end
