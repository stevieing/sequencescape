#!/usr/bin/env ruby
#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
# This script is massively faster than using grep as it allows us to do a single simple reg ex.
filtered_tables = ["aliquots", "archived_properties", "asset_audits", "asset_barcodes", "asset_creation_parents", "asset_creations", "asset_group_assets", "asset_groups", "asset_links", "assets", "attachments", "audits", "batch_requests", "batches", "billing_events", "bulk_transfers", "comments", "container_associations", "db_files", "delayed_jobs", "depricated_attempts", "documents", "documents_shadow", "events", "external_properties", "faculty_sponsors", "failures", "identifiers", "implements", "items", "lab_events", "lane_metadata", "location_associations", "lots", "orders", "pac_bio_library_tube_metadata", "permissions", "plate_conversions", "plate_metadata", "plate_owners", "plate_volumes", "pre_capture_pool_pooled_requests", "pre_capture_pools", "project_metadata", "projects", "qc_decision_qcables", "qc_decisions", "qc_files", "qcable_creators", "qcables", "quotas_bkp", "request_events", "request_informations", "request_metadata", "request_quotas_bkp", "requests", "sample_manifests", "sample_metadata", "sample_registrars", "samples", "sanger_sample_ids", "specific_tube_creation_purposes", "stamp_qcables", "stamps", "state_changes", "studies", "study_metadata", "study_reports", "study_samples", "study_samples_backup", "submissions", "submitted_assets", "tag_layouts", "transfers", "tube_creation_children", "uuids", "well_attributes", "well_links", "well_to_tube_transfers", "workflow_samples"]

while line = gets
  match = /^INSERT INTO `([^`]+)`/.match(line)
  next if match && filtered_tables.include?(match[1])
  puts line
end
