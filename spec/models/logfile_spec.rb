require 'rails_helper'

RSpec.describe Logfile, type: :model do
  let(:gzip_file) { "/private/var/log/system.log.0.gz" }
  let(:bzip2_file) { "/private/var/log/wifi.log.0.bz2" }

  it "extracts bz2" do
    contents = described_class.new(file_path: bzip2_file).extract_contents
    expect(contents.length).to be > 10_000
  end

  it 'extracts gzip' do
    contents = described_class.new(file_path: gzip_file).extract_contents
    expect(contents.length).to be > 10_000
  end
end
