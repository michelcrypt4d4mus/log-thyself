class LogEventFilter
  PRNG = Random.new(2385)

  FILTER_DEFINITIONS = [
    {
      comment: "This one plugin has spammed like 50GB of my hard drive. Improved by stopping coreaudiod but that's not a great long term solution",
      matchers: {
        sender_process_name: 'BTAudioHALPlugin',
        event_message: [
          'XPC server error: Connection invalid',
          'Invalidating all (0) audio devices',
          'Starting BTAudioPlugin for <private>',
          'Register audio plugin connection with bluetoothd'
        ]
      },
      allowed?: Proc.new do |event|
        rng = PRNG.rand(100)
        #Rails.logger.debug("d100 roll: #{rng}")
        rng == 1
      end
    },
    {
      comment: "Testing",
      matchers: {
        process_name: [
          'dasd',
          'kernel',
          'powerd',
          'corebrightnessd',
        ]
      },
      allowed?: Proc.new do |event|
        Rails.logger.info("Filtering an event #{event.attributes}")
        false
      end
    }
  ]

  def self.build_filters!
    @filters = FILTER_DEFINITIONS.map { |f| new(f.except(:comment)) }
    Rails.logger.info("Built #{@filters.size} filters")
  end

  # All must allow an event for event to be recorded
  def self.allow?(event)
    @filters.all? { |f| f.allow?(event) }
  end

  def initialize(rule)
    @rule = rule
  end

  def allow?(event)
    if applicable?(event)
      #Rails.logger.debug("Filter is applicable.")
      @rule[:allowed?].call(event)
    else
      true
    end
  end

  # Check the properties match before applying the proc
  def applicable?(event)
    matchers = @rule[:matchers]

    matchers.all? do |col_name, value|
      return false unless event[col_name]

      if value.is_a?(Array)
        value.include?(event[col_name])
      else
        value == event[col_name]
      end
    end
  end
end
