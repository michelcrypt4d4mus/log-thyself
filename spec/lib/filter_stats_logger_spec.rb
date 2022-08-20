RSpec.describe FilterStatsLogger do
  let(:stats_logger) { described_class.new }

  context 'arithmetic' do
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
      stats_logger.event_counts = event_counts
      expect(stats_logger.total_events(:blocked)).to eq(368)
      expect(stats_logger.total_events(:allowed)).to eq(632)
    end
  end
end
