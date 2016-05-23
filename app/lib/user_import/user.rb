module UserImport
  class User
    attr_accessor :first_name, :last_name, :email_address, :reports_to_user_email

    def initialize(row)
      @row = row
      @first_name, @last_name, @email_address, @reports_to_user_email = row
    end

    def ready_to_create?(other_emails_in_spreadsheet)
      # if the user doesn't report to anyone,
      # or their manager is already saved,
      # or their manager's email does not appear in the email column of the spreadsheet
      # then the account can be created
      other_emails = other_emails_in_spreadsheet.compact.map { |e| e.downcase }

      reports_to_user_email.blank? || ::User.find_by(email_address:reports_to_user_email) || !other_emails.include?(reports_to_user_email)
    end

    def email
      @email.try(:downcase)
    end

    def reports_to_user_email
      @reports_to_user_email.downcase if @reports_to_user_email.present?
    end

    def as_params
      {
        first_name: first_name, last_name: last_name, email_address: email_address,
        parent_id: parent_id
      }
    end

    def parent_id
      ::User.where(email_address: reports_to_user_email).pluck(:id).first
      #parent = ::User.find_by(email_address: reports_to_user_email)
      #parent.present? ? parent.id : nil
    end

    def row
      @row
    end

    def name_and_email
      "#{first_name} #{last_name} (#{email_address})"
    end

    def exists?
      existing_user.present?
    end

    def existing_user
      ::User.find_by(email_address: email_address)
    end

    def email_invalid?
      !self.class.email_valid?(@email_address)
    end

    def self.email_valid?(email_address)
      email.to_s.match(/\A.+@.+\z/)
    end
  end
end
