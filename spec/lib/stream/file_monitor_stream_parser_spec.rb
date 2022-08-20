RSpec.describe FileMonitorStreamParser do
  context 'stream' do
    let(:json_fixture) { file_fixture('file_monitor_100_lines.txt') }
    let(:stream_parser) { described_class.new(read_from_file: json_fixture) }

    it 'processes correctly' do
      stream_parser.parse_stream! { |record| FileEvent.new(record).save! }
      expect(FileEvent.where(is_process_signed_as_reported: true).count).to eq(7)
      expect(FileEvent.where(event_type: 'NOTIFY_OPEN').count).to eq(3)
      expect(FileEvent.where(event_type: 'NOTIFY_CLOSE').count).to eq(3)
      expect(FileEvent.where(event_type: 'NOTIFY_WRITE').count).to eq(1)
      expect(FileEvent.where(uid: 0).count).to eq(6)
    end
  end
end
