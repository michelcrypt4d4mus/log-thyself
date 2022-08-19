require 'rails_helper'

RSpec.describe Logfile, type: :model do
  context 'extraction' do
    let(:gzip_file) { "/private/var/log/system.log.0.gz" }
    let(:bzip2_file) { "/private/var/log/wifi.log.0.bz2" }
    let(:asl_file) { Dir[File.join(described_class::VAR_LOG, 'DiagnosticMessages/*.asl')].first }

    it "extracts bz2" do
      contents = described_class.new(file_path: bzip2_file).extract_contents
      expect(contents.length).to be > 10_000
    end

    it 'extracts gzip' do
      contents = described_class.new(file_path: gzip_file).extract_contents
      expect(contents.length).to be > 10_000
    end

    it 'extracts asl' do
      contents = described_class.new(file_path: asl_file).extract_contents
      expect(contents.length).to be > 100
    end

    context 'followed by loading' do
      let(:fixture_dir) { File.join(Rails.root, File.dirname(file_fixture('multiline_syslog_text.log'))) }

      it 'loads all the files' do
        described_class.load_all_files_in_directory!(fixture_dir)
        expect(described_class.count).to eq(4)
        expect(LogfileLine.count).to eq(4087)
        two_rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{LogfileLine.table_name} ORDER BY id LIMIT 2")
        two_line_lengths = two_rows.map { |r| r['line'].length }
        expect(two_line_lengths).to eq([745, 746])
      end
    end
  end

  context 'file type handling' do
    include_context 'logfiles'

    context 'closed?' do
      let(:closed_logs) do
        [
          asl,
          asl_manager_closed,
          diagnostic,
          homebrew_post_install,
          system_closed,
          wifi_closed,
        ]
      end

      let(:open_logs) do
        [
          wifi_open,
          system_open,
        ]
      end

      it 'determines open correctly' do
        open_logs.each do |log|
          status = described_class.new(file_path: log).open?
          puts "\n#{log} is closed but should be open!" unless status
          expect(status).to be true
        end
      end

      it 'determines closed correctly' do
        closed_logs.each do |log|
          status = described_class.new(file_path: log).closed?
          puts "\n#{log} is open but should be closed!" unless status
          expect(status).to be true
        end
      end
    end
  end
end
