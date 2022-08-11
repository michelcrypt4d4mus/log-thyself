# Extracts FileEvents from FileMonitor's JSON output and stores them along with the
# original JSON blob in case you want the other properties.
#
# JSON_PATHS = {
#   event_timestamp:      "$.timestamp",
#   event_type:           "$.event",
#   file:                 "$.file.destination",
#   uid:                  "$.file.process.uid",
#   pid:                  "$.file.process.pid",
#   ppid:                 "$.file.process.ppid",
#   rpid:                 "$.file.process.rpid",
#   process_name:         "$.file.process.name",
#   reported_signing_id:  "$.file.process.'signing info (reported)'.signingID",
#   computed_signing_id:  "$.file.process.'signing info (computed)'.signatureID"
# }


class FileEvent < ApplicationRecord
  ES_EVENT_TYPE_PREFIX = 'ES_EVENT_TYPE_'

  # Keys are columns we want to extract, values are JSONPath locations of the data
  JSON_PATHS = {
    event_type: '$.event',
    event_timestamp: '$.timestamp',
  }

  FILE_PATH = '$.file'
  PROCESS_PATH = FILE_PATH + '.process'
  JSON_PATHS.merge!(file: FILE_PATH + '.destination')

  %w(uid pid ppid rpid).each do |process_col|
    JSON_PATHS.merge!(process_col.to_sym => PROCESS_PATH + '.' + process_col)
  end

  JSON_PATHS.merge!(
    process_name: PROCESS_PATH + '.name',
    reported_signing_id: PROCESS_PATH + ".'signing info (reported)'.signingID",
    computed_signing_id: PROCESS_PATH + ".'signing info (computed)'.signatureID"
  )

  # Construct an instance of FileEvent from JSON
  def self.from_json(json)
    row = JSON_PATHS.inject({ raw_event: JSON.parse(json) }) do |row, (col_name, jsonpath)|
      # TODO: reparsing for every column is stupid; just ude dig()
      row[col_name] = JsonPath.on(json, jsonpath)[0]
      row
    end

    row[:event_type].delete_prefix!(ES_EVENT_TYPE_PREFIX)
    row[:is_process_signed_as_reported] = (row[:computed_signing_id] == row[:reported_signing_id])
    row.delete(:reported_signing_id) if row[:is_process_signed_as_reported]

    if row[:computed_signing_id].nil? || !row[:is_process_signed_as_reported]
      pretty_json = JSON.pretty_generate(row[:raw_event])
      Rails.logger.warn("No signature or mismatched signer for process:\n\nROW: #{row}\n\nJSON #{pretty_json}")
    end

    new(row)
  end
end
