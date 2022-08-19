RSpec.shared_context 'logfiles' do
  let(:var_log) { Logfile::VAR_LOG }
  let(:asl_dir) { File.join(var_log, 'asl') }
  let(:asl) { File.join(asl_dir, '2022.08.09.G80.asl') }
  let(:asl_manager_closed) { File.join(asl_dir, 'Logs/aslmanager.20220810T034511-04') }
  let(:wifi_open) { File.join(var_log, 'wifi.log') }
  let(:wifi_closed) { "#{wifi_open}.0.bz2" }
  let(:system_open) { File.join(var_log, 'system.log') }
  let(:system_closed) { "#{system_open}.0.bz2" }
  let(:diagnostic) { File.join(var_log, 'DiagnosticReports/shutdown_stall_2022-08-11-051122_nf32piofn2p3ofn23.shutdownStall') }
  let(:homebrew_post_install) { '/Library/Logs/Homebrew/python@3.10/post_install.01.python3' }
  let(:bluetooth_capture) { File.join(var_log, 'bluetooth_capture.pklg')}
end
