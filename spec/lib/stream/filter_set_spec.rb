RSpec.describe FilterSet do
  include_context 'log events'

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
    let(:filter_set) { described_class.new(FilterDefinitions::FILTER_DEFINITIONS) }

    it 'rejects the right pct of the time' do
      acceptances = (0..tries).to_a.select { |_| filter_set.allow?(filtered_event) }
      expect(acceptances.size > 90).to be_truthy
      expect(acceptances.size < 110).to be_truthy
    end
  end
end
