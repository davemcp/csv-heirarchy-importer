require 'spec_helper'

email_pairs = [
  ["jerry@email.com", "george@email.com"],
  ["larry@email.com", "jerry@email.com"],
  ["larry@email.com", "elaine@email.com"],
  ["cbs@email.com", "larry@email.com"],
  [nil, "cbs@email.com"]
]

rows = [
  ["Mark ", "Middleton ", "mark.middleton@roq.net.au", nil],
  ["Mark ", "Jones", "mark.jones@roq.net.au", "jim.frantzis@roq.net.au"],
  ["Toni", "Sisson", "toni.sisson@roq.net.au", "mark.middleton@roq.net.au"],
  ["Demtrios", "Frantzis", "jim.frantzis@roq.net.au", "mark.middleton@roq.net.au"],
  ["Desley", "Jones", "desley.jones@roq.net.au", "mark.middleton@roq.net.au"],
  ["Christopher", "Smyth ", "chris.smyth@roq.net.au", "jim.frantzis@roq.net.au"],
  ["Scott", "Millett", "scott.millett@roq.net.au", "chris.smyth@roq.net.au"],
  ["Troy ", "Marshall", "troy.marshall@roq.net.au ", "chris.smyth@roq.net.au"],
  ["Huong", "Nguyen ", "huong.nguyen@roq.net.au", "toni.sisson@roq.net.au "],
  ["Alicia ", "Moo ", "alicia.moo@roq.net.au", "desley.jones@roq.net.au "],
  ["Debbie", "Shannon", "debbie.shannon@roq.net.au", "toni.sisson@roq.net.au "]
]

rows_missing_user_email = rows.map {|r|
  new_row = r.clone
  new_row[2] = nil if new_row[2] == "toni.sisson@roq.net.au"
  new_row
}

unless defined?(User) || $integration
  class User < ActiveRecord::Base
  end
end

describe UserImporter do
  let(:import_job) { UserImportJob.create!(user: admin, data: rows.to_s) }
  let(:builder) { UserHierarchyBuilder.new(email_pairs).tap { |b| b.prepare } }
  let(:admin) { FactoryGirl.create(:user) }
  let(:importer) { UserImporter.new(import_job: import_job, rows: rows) }

  context 'with missing user email' do
    let(:importer) { UserImporter.new(rows: rows_missing_user_email, import_job: import_job) }

    it 'returns false and lists the error when no user email for a user' do
      expect(importer.import_rows).to eql(false)
    end

    it 'has errors about missing user emails' do
      importer.import_rows
      expect(importer.errors.first[:type]).to eql("Missing User emails")
    end
  end

  context 'without missing user email' do
    it 'loads a list of users' do
      expect(importer.import_rows).to eql(true)
    end

    it 'does not have erros' do
      importer.import_rows
      expect(importer.errors.size).to eql(0)
    end
  end

  context 'processes the imported tree and saves the users into the database' do
    let(:builder) { UserHierarchyBuilder.new([]) }
    let(:importer) { UserImporter.new(rows: rows, import_job: import_job) }
    it 'creates the users' do
      importer.import_rows
      expect(importer.errors.size).to eql(0)
    end

  end
end
