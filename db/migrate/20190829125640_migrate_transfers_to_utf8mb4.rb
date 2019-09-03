# frozen_string_literal: true

# Autogenerated migration to convert transfers to utf8mb4
class MigrateTransfersToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('transfers', from: 'latin1', to: 'utf8mb4')
  end
end