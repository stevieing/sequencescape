#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2015 Genome Research Ltd.
class AssetAudit < ActiveRecord::Base
  include Api::AssetAuditIO::Extensions
  include Uuid::Uuidable
  include ::Io::AssetAudit::ApiIoSupport

  belongs_to :asset

  cattr_reader :per_page
  @@per_page = 500

  validates_presence_of :asset
  validates_presence_of :key
  validates_format_of :key, :with => /^[\w_]+$/i, :message => I18n.t('asset_audit.key_format'), :on => :create

  # Disabled in the initial events release. One enabling ensure historical audits
  # get broadcast
  # after_create :broadcast_event

  private

  def broadcast_event
    BroadcastEvent::AssetAudit.create!(:seed=>self,:user=>User.find_by_login(created_by),:created_at=>created_at)
  end


end

