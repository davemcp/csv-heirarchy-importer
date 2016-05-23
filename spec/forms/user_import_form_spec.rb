require 'spec_helper'

describe UserImportForm do
  let(:spreadsheet) { double(path: 'spec/support/fixtures/users.csv', original_filename: 'users.csv') }
  let(:manager) { FactoryGirl.create(:user) }
  let(:current_user) { FactoryGirl.create(:user, parent_id: manager.id) }
  let(:circular_spreadsheet) { double(path: 'spec/support/fixtures/bulk_users_circular_managers.csv', original_filename: 'bulk_users_circular_managers.csv') }
  let(:form_params) {
    {
      spreadsheet: spreadsheet,
      current_user: current_user
    }
  }
  let(:circular_params) {
    {
      spreadsheet: circular_spreadsheet,
    }
  }
  let(:form) { UserImportForm.new(form_params) }
  let(:circular_form) { UserImportForm.new(circular_params) }
  let(:user_hierarchy_builder) { UserHierarchyBuilder.new }

  before do
    allow(circular_form).to receive(:existing_email_pairs) {
      [
        ["manager@example.com.au", "aldomanganaro123@.example.com"],
        ["manager@example.com.au", "amanda.waldon@example.com.au"],
        [nil, "manager@example.com.au"],
        ["manager@example.com.au", "amelia.thompson@example.com.au"]
      ]
    }
    allow(form).to receive(:existing_email_pairs) {
      [
        ["manager@example.com.au", "aldomanganaro123@.example.com"],
        ["manager@example.com.au", "amanda.waldon@example.com.au"],
        [nil, "manager@example.com.au"],
        ["manager@example.com.au", "amelia.thompson@example.com.au"]
      ]
    }
  end

  it 'opens the uploaded spreadsheet' do
    expect(form.send(:open_spreadsheet)).to be_a(Roo::CSV)
  end

  it 'detects whether the headers are present in the spreadsheet' do
    expect(form.headers_present?).to eq(true)
  end

  it 'returns the rows from the spreadsheet' do
    expect(form.rows.size).to eq(4)
  end

  it 'creates and returns a new hierarchy builder' do
    expect(user_hierarchy_builder).to be_a(UserHierarchyBuilder)
  end

  it 'creates and returns a new user importer' do
    expect(form.user_importer).to be_a(UserImporter)
    expect(form.user_importer.errors.size).to eq(0)
  end

  it 'handles mixed case file extensions' do
    allow(form).to receive(:spreadsheet) { double(path: 'spec/support/fixtures/MiXeDCaSe.CsV', original_filename: 'MiXeDCaSe.CsV') }
    form.instance_variable_set(:@ss, nil)
    expect(form.send(:open_spreadsheet)).to be_a(Roo::CSV)
  end

  it 'handles upper case file extensions' do
    allow(form).to receive(:spreadsheet) { double(path: 'spec/support/fixtures/UPPER.XLSX', original_filename: 'UPPER.XLSX') }
    form.instance_variable_set(:@ss, nil)
    expect(form.send(:open_spreadsheet)).to be_a(Roo::Excelx)
  end

end
