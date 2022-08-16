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

  context 'arithmetic' do
    before { described_class.build_filters! }

    let(:event_counts) do
      {
        "fseventsd"  =>                  {:allowed  =>  1, :blocked  =>  0},
        "opendirectoryd"  =>             {:allowed  =>  4, :blocked  =>  0},
        "Activity Monitor"  =>           {:allowed  =>  14, :blocked  =>  109},
        "cfprefsd"  =>                   {:allowed  =>  5, :blocked  =>  0},
        "distnoted"  =>                  {:allowed  =>  2, :blocked  =>  0},
        "log"  =>                        {:allowed  =>  4, :blocked => 0},
        "mds" =>                         {:allowed => 13, :blocked => 0},
        "tccd" =>                        {:allowed => 71, :blocked => 10},
        "mds_stores" =>                  {:allowed => 6, :blocked => 0},
        "coreservicesd" =>               {:allowed => 4, :blocked => 0},
        "ProcessMonitor" =>              {:allowed => 46, :blocked => 0},
        "WindowServer" =>                {:allowed => 32, :blocked => 22},
        "kernel" =>                      {:allowed => 2, :blocked => 4},
        "Electron" =>                    {:allowed => 0, :blocked => 13},
        "runningboardd" =>               {:allowed => 6, :blocked => 59},
        "cloudd" =>                      {:allowed => 1, :blocked => 0},
        "launchservicesd" =>             {:allowed => 2, :blocked => 0},
        "com.apple.WebKit.WebContent" => {:allowed => 1, :blocked => 0},
        "diskarbitrationd" =>            {:allowed => 3, :blocked => 0},
        "apsd" =>                        {:allowed => 255, :blocked => 151},
        "powerd" =>                      {:allowed => 2, :blocked => 0},
        "mDNSResponder" =>               {:allowed => 128, :blocked => 0},
        "symptomsd" =>                   {:allowed => 14, :blocked => 0},
        "usernoted" =>                   {:allowed => 1, :blocked => 0},
        "secd" =>                        {:allowed => 1, :blocked => 0},
        "identityservicesd" =>           {:allowed => 6, :blocked => 0},
        "StatusKitAgent" =>              {:allowed => 2, :blocked => 0},
        "sharingd" =>                    {:allowed => 1, :blocked => 0},
        "imagent" =>                     {:allowed => 1, :blocked => 0},
        "callservicesd" =>               {:allowed => 2, :blocked => 0},
        "SafariBookmarksSyncAgent" =>    {:allowed => 1, :blocked => 0},
        "cloudpaird" =>                  {:allowed => 1, :blocked => 0}
      }
    end

    it 'sums correctly' do
      described_class.event_counts = event_counts
      expect(described_class.total_events).to eq(1000)
      expect(described_class.total_events(:blocked)).to eq(368)
      expect(described_class.total_events(:allowed)).to eq(632)
    end
  end

end
