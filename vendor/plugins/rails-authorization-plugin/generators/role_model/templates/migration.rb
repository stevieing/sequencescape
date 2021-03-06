#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) <%= '2015'; DateTime.now.year %> Genome Research Ltd.
class <%= migration_name %> < ActiveRecord::Migration

  def self.up
    create_table :<%= (table_name < 'users') ? "#{table_name}_users" : "users_#{table_name}" %>, :id => false, :force => true  do |t|
      t.integer :user_id, :<%= singular_name %>_id
      t.timestamps
    end

    create_table :<%= table_name %>, :force => true do |t|
      t.string  :name, :authorizable_type, :limit => 40
      t.integer :authorizable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :<%= table_name %>
    drop_table :<%= (table_name < 'users') ? "#{table_name}_users" : "users_#{table_name}" %>
  end

end
