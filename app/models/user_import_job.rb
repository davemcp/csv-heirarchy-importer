class UserImportJob < ActiveRecord::Base
  belongs_to :user, class_name: '::User'

  validates_presence_of :user

  enum job_state: %w(unstarted finished failed)
end
