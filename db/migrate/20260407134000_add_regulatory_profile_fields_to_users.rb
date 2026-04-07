class AddRegulatoryProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :residential_address, :text
    add_column :users, :date_of_birth, :date
    add_column :users, :sin, :string
  end
end
