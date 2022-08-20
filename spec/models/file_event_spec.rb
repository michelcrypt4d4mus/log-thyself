require 'rails_helper'

RSpec.describe FileEvent, type: :model do
  let(:event) { file_fixture('file_monitor_event.json').read }

  it 'parses correctly' do
    row = described_class.new_from_json(event)

    expect(row.attributes).to eq(
      described_class.new({
        event_timestamp: "2022-08-10 03:58:40 +0000",
        event_type: "NOTIFY_WRITE",
        file: "/dev/ttys001",
        uid: 501,
        pid: 23875,
        ppid: 1250,
        rpid: 779,
        process_name: "FileMonitor",
        process_arguments: nil,
        computed_signing_id: "com.objective-see.filemonitor",
        is_process_signed_as_reported: true,
        signature_authorities: '["Developer ID Application: Objective-See, LLC (VBG97UB4TA)", "Developer ID Certification Authority", "Apple Root CA"]',
        signature_signer: 'Developer ID',
        raw_event: JSON.parse(event)
      }).attributes
    )
  end
end
