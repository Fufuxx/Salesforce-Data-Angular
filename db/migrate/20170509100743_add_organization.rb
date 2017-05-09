class AddOrganization < ActiveRecord::Migration[5.0]
  def change
    create_table :organizations do |t|
      t.string :sfdc_id
      t.integer :user_id
      t.string :name
      t.string :username

      t.string :orgname
      t.string :orgtype
      t.datetime :orgexpiry

      t.binary :logo

      t.string :token
      t.string :instanceurl
      t.string :metadataurl
      t.string :serviceurl
      t.string :refreshtoken

      t.string :division

      t.datetime :last_sign_in_date
      t.datetime :org_created_date

      t.integer :exp_notice_level
      t.integer :whitelist_id
      t.integer :organization_type_id

      t.timestamps
    end
  end
end
