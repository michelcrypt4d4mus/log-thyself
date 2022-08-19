RSpec.describe FileStreamer do
  include_context 'logfiles'

  context 'shell commands' do
    shared_examples 'command' do |file_path, expected_read_command, expected_stream_command|
      let(:file_streamer) { described_class.new(file_path) }

      it 'gets the right read command' do
        expect(file_streamer.shell_command_to_read).to eq(expected_read_command)
      end

      it 'gets the right stream command' do
        if expected_stream_command.is_a?(Class)
          expect { file_streamer.shell_command_to_stream }.to raise_error(expected_stream_command)
        else
          expect(file_streamer.shell_command_to_stream).to eq(expected_stream_command)
        end
      end
    end

    it 'handles asl files correctly' do
      expect(described_class.new(asl).shell_command_to_read).to eq("cat \"#{asl}\" | syslog -F raw -T utc.6 -f")
      expect { described_class.new(asl).shell_command_to_stream }.to raise_error(RuntimeError)
    end

    it 'handles pklg files correctly' do
      expect(described_class.new(bluetooth_capture).shell_command_to_read).to eq("tshark -r \"#{bluetooth_capture}\"")
      expect { described_class.new(bluetooth_capture).shell_command_to_stream }.to raise_error(RuntimeError)
    end

    it_behaves_like 'command', 'file.log', 'cat "file.log"', 'tail -c +0 -F "file.log"'
    it_behaves_like 'command', 'db.gz', 'gunzip -c "db.gz"', 'tail -c +0 -F "db.gz" | gunzip -c'
  end
end
