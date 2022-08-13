RSpec.describe FileMonitorStreamParser do
  context 'stream' do
    let(:shell_command) { "cat #{file_fixture('file_monitor_100_lines.txt')}" } # Only 7 rows...
    let(:stream_parser) { described_class.new(shell_command: shell_command) }

    it 'processes correctly' do
      stream_parser.parse_stream! { |record| record.save! }
      expect(FileEvent.where(is_process_signed_as_reported: true).count).to eq(7)
      expect(FileEvent.where(event_type: 'NOTIFY_OPEN').count).to eq(3)
      expect(FileEvent.where(event_type: 'NOTIFY_CLOSE').count).to eq(3)
      expect(FileEvent.where(event_type: 'NOTIFY_WRITE').count).to eq(1)
      expect(FileEvent.where(uid: 0).count).to eq(6)
    end
  end
end
