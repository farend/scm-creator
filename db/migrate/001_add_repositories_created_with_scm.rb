class AddRepositoriesCreatedWithScm < ActiveRecord::Migration

    def self.up
        add_column :repositories, :created_with_scm, :boolean, :default => false, :null => false
    end

    def self.down
        remove_column :repositories, :created_with_scm
    end

end
