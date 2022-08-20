RSpec.shared_context 'log events' do
  let(:missing_message_event) { build(:mac_os_system_log, sender_process_name: 'BTAudioHALPlugin') }
  let(:mismatched_message_event) { missing_message_event.tap { |m| m.event_message = 'ny state of mind' } }
  let(:filtered_event) { missing_message_event.tap { |m| m.event_message = "XPC server error: Connection invalid" } }
end
