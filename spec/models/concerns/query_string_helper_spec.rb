
RSpec.describe QueryStringHelper do
  let(:includer) { Struct.new(:field) { include QueryStringHelper } }
  let(:extender) { Struct.new(:field) { extend QueryStringHelper } }

  context 'quoted joins' do
    let(:list) { %w[a] + [5, true] }
    let(:single_quoted) { "'a', '5', 'true'" }
    let(:double_quoted) { single_quoted.tr("'", '"') }

    it 'single quotes correctly' do
      expect(includer.new.single_quoted_join(list)).to eq(single_quoted)
      expect(extender.single_quoted_join(list)).to eq(single_quoted)
    end

    it 'double quotes correctly' do
      expect(includer.new.double_quoted_join(list)).to eq(double_quoted)
      expect(extender.double_quoted_join(list)).to eq(double_quoted)
    end

    it 'handles join_string options correctly' do
      expect(includer.new.single_quoted_join(list, join_string: ';')).to eq("'a';'5';'true'")
    end
  end
end
