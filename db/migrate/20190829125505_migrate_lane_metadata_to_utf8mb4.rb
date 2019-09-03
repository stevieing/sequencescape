# frozen_string_literal: true

# Autogenerated migration to convert lane_metadata to utf8mb4
class MigrateLaneMetadataToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('lane_metadata', from: 'latin1', to: 'utf8mb4')
  end
end