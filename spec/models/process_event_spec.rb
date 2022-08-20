require 'rails_helper'

PROCESS_EVENT_JSON=<<-JSON
{
  "event": "ES_EVENT_TYPE_NOTIFY_EXEC",
  "timestamp": "2022-08-13 09:53:50 +0000",
  "process": {
    "exit code": 0,
    "pid": 41874,
    "name": "mdworker_shared",
    "path": "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/Metadata.framework/Versions/A/Support/mdworker_shared",
    "uid": 89,
    "architecture": "Apple Silicon",
    "arguments": [
      "/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Versions/A/Support/mdworker_shared",
      "-s",
      "mdworker",
      "-c",
      "MDSImporterWorker",
      "-m",
      "com.apple.mdworker.shared"
    ],
    "ppid": 1,
    "rpid": 41874,
    "ancestors": [
      1
    ],
    "signing info (reported)": {
      "csFlags": 570522385,
      "platformBinary": 1,
      "signingID": "com.apple.mdworker_shared",
      "teamID": "",
      "cdHash": "B0894FE16C9C5490551248B3E4486D53A783FDE6"
    },
    "signing info (computed)": {
      "signatureID": "com.apple.mdworker_shared",
      "signatureStatus": 0,
      "signatureSigner": "Apple",
      "signatureAuthorities": [
        "Software Signing",
        "Apple Code Signing Certification Authority",
        "Apple Root CA"
      ]
    }
  }
}
JSON

RSpec.describe ProcessEvent, type: :model do
  it 'creates records with the right properties' do
    row = described_class.new_from_json(PROCESS_EVENT_JSON)

    expect(row.attributes).to eq(
      described_class.new({
        event_timestamp: '2022-08-13T09:53:50',
        event_type: "NOTIFY_EXEC",
        process_path: "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/Metadata.framework/Versions/A/Support/mdworker_shared",
        process_name: "mdworker_shared",
        process_arguments: '/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Versions/A/Support/mdworker_shared -s mdworker -c MDSImporterWorker -m com.apple.mdworker.shared',
        uid: 89,
        pid: 41874,
        ppid: 1,
        rpid: 41874,
        exit_code: 0,
        is_process_signed_as_reported: true,
        signature_signer: "Apple",
        signature_authorities: "[\"Software Signing\", \"Apple Code Signing Certification Authority\", \"Apple Root CA\"]",
        computed_signing_id: "com.apple.mdworker_shared",
        reported_signing_id: nil,
        raw_event: JSON.parse(PROCESS_EVENT_JSON)
      }).attributes
    )
  end
end
