RSpec.describe LogEventFilter do
  include_context 'log events'

  let(:tries) { 10_000 }

  let(:filter_rule) { FilterDefinitions::FILTER_DEFINITIONS.first }
  let(:col_matchers) { filter_rule[:matchers]}
  let(:filter) { described_class.new(filter_rule) }

  it 'rejects mismatches' do
    expect(filter.applicable?(missing_message_event)).to be_falsy
    expect(filter.applicable?(mismatched_message_event)).to be_falsy
  end

  context 'applicable events' do
    let(:rule_factory) { { comment: '', allowed?: true} }  # TODO: use a real factory
    let(:regex_filter) { described_class.new(rule_factory.merge(matchers: { process_name: /sleep/ })) }
    let(:regex_event) { { process_name: 'sleep_is_the_cousin_of_death' } }

    it 'identifies them with regexes' do
      expect(regex_filter.applicable?(regex_event)).to be true
    end

    it 'identifies them with string matching' do
      expect(filter.applicable?(filtered_event)).to be_truthy
    end

    it 'rejects the right pct of the time' do
      acceptances = (0..tries).to_a.select { |_| filter.allow?(filtered_event) }
      expect(acceptances.size > 90).to be_truthy
      expect(acceptances.size < 110).to be_truthy
    end
  end
end
