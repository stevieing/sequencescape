#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class SetBaseRequestPurposes < ActiveRecord::Migration

  def self.qc_type?(rt)
    ['qc_miseq_sequencing'].include?(rt.key)
  end

  def self.control_request?(rt)
    rt.key.present? && rt.key.end_with?('_control')
  end

  def self.purpose(key)
    @rp||=Hash[RequestPurpose.all.map {|rp| [rp.key,rp]}]
    @rp[key]
  end

  def self.internal?(rt)
    rc = rt.request_class
    return false if rc <= CherrypickForPulldownRequest
    return true if rc <= TransferRequest
    return true if rc <= CreateAssetRequest
    false
  end

  def self.purpose_for(rt)
    return purpose('qc')        if qc_type?(rt)
    return purpose('control')   if control_request?(rt)
    return purpose('internal')  if internal?(rt)
    return purpose('standard')
  end

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_each do |rt|
        rt.request_purpose = purpose_for(rt)
        rt.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_each do |rt|
        rt.request_purpose = nil
        rt.save!
      end
    end
  end
end
