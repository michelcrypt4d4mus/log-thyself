# Common features of events from the Objective See tools
#
# JSON_PATHS = {
#   event_timestamp:       "$.timestamp",
#   event_type:            "$.event",
#   uid:                   "$.file.process.uid",
#   pid:                   "$.file.process.pid",
#   ppid:                  "$.file.process.ppid",
#   rpid:                  "$.file.process.rpid",
#   process_name:          "$.file.process.name",
#   process_arguments:     "$.file.process.arguments",
#   reported_signing_id:   "$.file.process.'signing info (reported)'.signingID",
#   computed_signing_id:   "$.file.process.'signing info (computed)'.signatureID",
#   signature_signer:      "$.file.process.'signing info (computed)'.signatureSigner",
#   signature_authorities: "$.file.process.'signing info (computed)'.signatureAuthorities"
# }

module ObjectiveSeeEvent
  extend ActiveSupport::Concern

  ES_EVENT_TYPE_PREFIX = 'ES_EVENT_TYPE_'
  FILE_PATH = '$.file'
  PROCESS_PATH = FILE_PATH + '.process'
  COMPUTED_SIGNING_INFO_PATH = PROCESS_PATH + ".'signing info (computed)'"

  # Keys are columns we want to extract, values are JSONPath locations of the data
  SHARED_JSON_PATHS = {
    event_type: '$.event',
    event_timestamp: '$.timestamp',
    process_name: PROCESS_PATH + '.name',
    process_arguments: PROCESS_PATH + '.arguments',
    reported_signing_id: PROCESS_PATH + ".'signing info (reported)'.signingID",
    computed_signing_id: COMPUTED_SIGNING_INFO_PATH + '.signatureID',
    signature_signer: COMPUTED_SIGNING_INFO_PATH + '.signatureSigner',
    signature_authorities: COMPUTED_SIGNING_INFO_PATH + '.signatureAuthorities'
  }

  %w(uid pid ppid rpid).each do |process_col|
    SHARED_JSON_PATHS.merge!(process_col.to_sym => PROCESS_PATH + '.' + process_col)
  end
end
