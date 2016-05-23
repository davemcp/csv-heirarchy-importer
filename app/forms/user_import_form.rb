class UserImportForm
  include SimpleFormObject

  attribute :spreadsheet, :file
  attribute :users
  attribute :current_user

  attr_accessor :csv_validation
  attr_accessor :created_users
  attr_reader :imported_users

  def rows
    return [] unless spreadsheet
    if headers_present?
      open_spreadsheet.drop(1)
    else
      open_spreadsheet
    end
  end

  def headers_present?
    open_spreadsheet.row(1).map { |col| col.to_s.downcase }.include?('email')
  end

  # load the users from the spreadsheet
  def users
    @users ||= rows.map { |r| UserImport::User.new(r) }
  end

  # load the users from the nested params
  def users=(params)
    @users = params.values.map { |r| UserImport::User.new(r.values) }
  end

  def emails
    rows.any? ? rows.transpose[2] : users.map(&:email)
  end

  def user_importer
    @user_importer ||= UserImporter.new(rows: rows, import_job: import_job)
  end

  def job_id
    import_job.id
  end

  def import_job
    @import_job ||= UserImportJob.create!(user: current_user, data: csv_rows)
  end

  def csv_rows
    CSV.generate do |csv|
      rows.each do |row|
        csv << row
      end
    end
  end

  def reports_to_user_emails
    @reports_to_user_emails ||= users.map(&:reports_to_user_email)
  end

  def reports_to_user_options_for(u)
    existing_reports + users.reject{ |us| us.email == u.email }
  end

  def existing_reports
    @existing_reports ||= User.order('lower(first_name) ASC, lower(last_name) ASC')
  end

  private

  def encoded_spreadsheet
    tmpfile = Tempfile.new(spreadsheet.original_filename, "#{ Rails.root }/tmp")
    tmpfile.write(File.read(spreadsheet.path).encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
    tmpfile.rewind
    tmpfile
  end

  def open_spreadsheet
    @ss ||= case File.extname(spreadsheet.original_filename).downcase
            when ".csv" then Roo::CSV.new(encoded_spreadsheet.path, csv_options: { encoding: Encoding::UTF_8 })
            when ".xls" then Roo::Excel.new(spreadsheet.path, file_warning: :ignore)
            when ".xlsx" then Roo::Excelx.new(spreadsheet.path, file_warning: :ignore)
            when '.ods' then Roo::OpenOffice.new(spreadsheet.path, file_warning: :ignore)
            else fail "Unknown file type: #{ spreadsheet.original_filename }"
            end
  end
end
