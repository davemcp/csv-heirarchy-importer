require "user_hierarchy_builder"
require "active_support/core_ext/object/blank"

class UserImporter
  attr_accessor :errors
  attr_reader :imported_users, :logger, :csv, :import_job

  MANAGER_EMAIL_INDEX = 3
  USER_EMAIL_INDEX = 2

  def initialize(logger: Rails.logger, rows:, import_job:)
    @errors = []
    @builder = UserHierarchyBuilder.new(existing_email_pairs).tap(&:prepare)
    @imported_users = []
    @logger = logger
    @csv = rows
    @import_job = import_job
  end

  def import_rows
    errors << { type: "Missing User emails", rows: rows_missing_user_email } if rows_missing_user_email.size > 0
    return false if errors.size > 0
    add_level csv
    return false if errors.size > 0
    save_tree
    true
  end

  private

  def existing_email_pairs
    User.joins("LEFT OUTER JOIN users as managers on users.parent_id = managers.id").pluck("managers.email_address manager_email, users.email_address user_email")
  end

  def save_tree
    @builder.walk do |node|
      if node.row
        imported_users << create_or_update_user(UserImport::User.new node.row)
      end
    end
  end

  # this creates or updates user with given params.
  def create_or_update_user(user)
    if user.exists?
      update_user(user.existing_user, user.as_params)
    else
      User.new(user.as_params)
    end
  rescue ActiveRecord::RecordInvalid => invalid
    errors << { type: "User unable to be saved #{ invalid }", rows: node.row }
  end

  def update_user(existing_user, user_params)
    existing_user.update(user_params)
    existing_user.reload
  end


  # this method attempts to add row to user hierarchy builder (and returns nothing if all added)
  # and recursively calls itself until either all imported or nothing more can be imported
  def add_level(import_rows)
    not_imported_rows = import_rows.reject do |r|
      mgr_email = r[MANAGER_EMAIL_INDEX]
      usr_email = r[USER_EMAIL_INDEX]
      @builder.import(mgr_email.nil? ? "" : mgr_email.strip, usr_email.nil? ? "" : usr_email.strip,  r)
    end

    return if not_imported_rows.empty?

    if not_imported_rows == import_rows
      errors << { type: "Unable to add the following rows", rows:  not_imported_rows }
    else
      add_level(not_imported_rows)
    end
  end

  def rows_missing_user_email
    @rows_missing_user_email ||= csv.reject { |r| r[2].presence }
  end
end
