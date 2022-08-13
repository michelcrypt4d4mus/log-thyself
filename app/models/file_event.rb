# Extracts FileEvents from FileMonitor's JSON output and stores them along with the
# original JSON blob in case you want the other properties.

class FileEvent < ApplicationRecord
  include ObjectiveSeeEvent

  JSON_PATHS = SHARED_JSON_PATHS.merge(file: FILE_PATH + '.destination')

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
