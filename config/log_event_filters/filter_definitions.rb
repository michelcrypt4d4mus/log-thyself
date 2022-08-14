class FilterDefinitions
  PRNG = Random.new(2385)

  LOG_EVENT_FILTERS = [
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
      comment: "Low level debug events",
      matchers: {
        process_name: [
          'corebrightnessd',
          'kernel',
          'powerd',
        ],
        message_type: 'Debug'
      },
      allowed?: ->(event) { false }
    }
  ]
end
