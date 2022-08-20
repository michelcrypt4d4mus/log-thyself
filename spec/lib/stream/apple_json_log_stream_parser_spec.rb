RSpec.describe AppleJsonLogStreamParser do
  let(:log_json) { file_fixture("log_show_output.json") }

  it 'parses a stream' do
    described_class.new("cat #{log_json}").parse_stream! do |row|
      MacOsSystemLog.new(row).save!
    end

    expect(MacOsSystemLog.count).to eq(132)
  end
end
