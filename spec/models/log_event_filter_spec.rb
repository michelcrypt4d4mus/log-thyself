RSpec.describe LogEventFilter do
  let(:tries) { 10_000 }

  let(:filter_rule) { FilterDefinitions::LOG_EVENT_FILTERS.first }
  let(:col_matchers) { filter_rule[:matchers]}
  let(:filter) { described_class.new(filter_rule) }

  let(:missing_col) { filter_rule[:matchers].except(:event_message) }
  let(:mismatched_data) { missing_col.merge(event_message: 'ny state of mind') }
  let(:match) { missing_col.merge(event_message: col_matchers[:event_message].first) }

  it 'has valid filter definitions' do
    expect { described_class.build_filters! }.not_to raise_error
  end

  it 'rejects mismatches' do
    expect(filter.applicable?(missing_col)).to be_falsy
    expect(filter.applicable?(mismatched_data)).to be_falsy
  end

  context 'applicable events' do
    let(:rule_factory) { { comment: '', allowed?: true} }  # TODO: use a real factory
    let(:regex_filter) { described_class.new(rule_factory.merge(matchers: { process_name: /sleep/ })) }
    let(:regex_event) { { process_name: 'sleep_is_the_cousin_of_death' } }

    it 'identifies them with regexes' do
      expect(regex_filter.applicable?(regex_event)).to be true
    end

    it 'identifies them with string matching' do
      expect(filter.applicable?(match)).to be_truthy
    end

    it 'rejects the right pct of the time' do
      acceptances = (0..tries).to_a.select { |_| filter.allow?(match) }
      expect(acceptances.size > 90).to be_truthy
      expect(acceptances.size < 110).to be_truthy
    end
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
