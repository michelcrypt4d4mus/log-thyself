RSpec.describe FilterSet do
  context 'filter definitions' do
    shared_examples 'valid' do |definition_klass|
      it 'is a valid set of filter definitions' do
        expect { described_class.new(definition_klass::FILTER_DEFINITIONS) }.not_to raise_error
      end
    end

    it_behaves_like 'valid', ObjectiveSeeEventFilterDefinitions
    it_behaves_like 'valid', FilterDefinitions
  end

  context 'with all the filters' do
    before { described_class.build_filters! }

    it 'rejects the right pct of the time' do
      acceptances = (0..tries).to_a.select { |_| LogEventFilter.allow?(match) }
      expect(acceptances.size > 90).to be_truthy
      expect(acceptances.size < 110).to be_truthy
    end
  end
end
