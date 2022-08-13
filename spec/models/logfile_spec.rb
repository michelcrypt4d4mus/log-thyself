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
      puts "ASL FILE: #{asl_file}"
      contents = described_class.new(file_path: asl_file).extract_contents
      expect(contents.length).to be > 100
    end
  end

  context 'file type handling' do
    let(:var_log) { described_class::VAR_LOG }
    let(:asl_dir) { File.join(var_log, 'asl') }
    let(:asl_open) { File.join(asl_dir, "#{Date.today.strftime('%Y.%m.%d')}.G80.asl") }
    let(:asl_closed) { File.join(asl_dir, '2022.08.09.G80.asl') }
    let(:asl_manager_closed) { File.join(asl_dir, 'Logs/aslmanager.20220810T034511-04') }
    let(:wifi_open) { File.join(var_log, 'wifi.log') }
    let(:wifi_closed) { "#{wifi_open}.0.bz2" }
    let(:system_open) { File.join(var_log, 'system.log') }
    let(:system_closed) { "#{system_open}.0.bz2" }
    let(:diagnostic) { File.join(var_log, 'DiagnosticReports/shutdown_stall_2022-08-11-051122_nf32piofn2p3ofn23.shutdownStall') }
    let(:homebrew_post_install) { '/Library/Logs/Homebrew/python@3.10/post_install.01.python3' }

    context 'closed?' do
      let(:closed_logs) do
        [
          asl_closed,
          asl_manager_closed,
          diagnostic,
          homebrew_post_install,
          system_closed,
          wifi_closed,
        ]
      end

      let(:open_logs) do
        [
          asl_open,
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

    context 'shell commands' do
      shared_examples 'command' do |file_path, expected_read_command, expected_stream_command|
        let(:logfile) { Logfile.new(file_path: file_path) }

        it 'gets the right read command' do
          expect(logfile.shell_command_to_read).to eq(expected_read_command)
        end

        it 'gets the right stream command' do
          expect(logfile.shell_command_to_stream).to eq(expected_stream_command)
        end
      end

      it_behaves_like 'command', 'db.asl', "syslog -f \"db.asl\"", "tail -c +0 -F \"db.asl\" | syslog -f"
      it_behaves_like 'command', 'file.log', 'cat "file.log"', 'tail -c +0 -F "file.log"'
      it_behaves_like 'command', 'db.gz', "syslog -f \"db.gz\"", "tail -c +0 -F \"db.asl\" | syslog -f"
    end
  end
end
