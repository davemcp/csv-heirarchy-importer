class CreateUserImportJobs < ActiveRecord::Migration
  def change
    create_table :user_import_jobs do |t|
      t.references :user
      t.text :data
      t.text :import_results
      t.text :import_errors
      t.integer :job_state, default: 0, null: false
    end
  end
end
