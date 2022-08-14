RSpec.describe SyslogStreamParser do
  context 'single line' do
    let(:line) do
      "2022-07-23 05:36:41.952880+0000 0x9cc      Default     0x0                  85     30   templateMigrator: (SystemMigrationUtils) [com.apple.mac.install:SystemMigration] Shoving Sandbox file:///Volumes/Data/Previous%20System/System/Library/AssetsV2/com_apple_MobileAsset_MacSoftwareUpdate/ssetData/boot/EFI/SMCJSONs/Mac-63001698E7A34814.json -> file:///System/Volumes/macOS/System/Library/AssetsV2/com_apple_MobileAsset_MacSoftwareUpdate/ssetData/boot/EFI/SMCJSONs/Mac-63001698E7A34814.json."
    end

    it 'parses a row' do
      result_hash = described_class.new(nil).process_log_entry(line)

      expect(result_hash).to eq({
        log_timestamp: '2022-07-23 05:36:41.952880+0000',
        thread_id: 2508,
        activity_identifier: 0,
        process_id: '85',
        process_name: 'templateMigrator',
        message_type: 'Default',
        event_type: 'logEvent',
        sender_process_name: 'SystemMigrationUtils',
        event_message: 'Shoving Sandbox file:///Volumes/Data/Previous%20System/System/Library/AssetsV2/com_apple_MobileAsset_MacSoftwareUpdate/ssetData/boot/EFI/SMCJSONs/Mac-63001698E7A34814.json -> file:///System/Volumes/macOS/System/Library/AssetsV2/com_apple_MobileAsset_MacSoftwareUpdate/ssetData/boot/EFI/SMCJSONs/Mac-63001698E7A34814.json.',
        subsystem: 'com.apple.mac.install',
        category: 'SystemMigration'
      })
    end
  end

  context 'stream from files' do
    let(:syslog_file) { file_fixture('multiline_syslog_text.log') }

    it 'parses a stream' do
      described_class.new(syslog_file).parse_stream! { |row| row.save! }
      expect(MacOsSystemLog.count).to eq(12)
    end
  end
end
