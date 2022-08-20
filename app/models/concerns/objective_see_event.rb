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
  include QueryStringHelper

  ES_EVENT_TYPE_PREFIX = 'ES_EVENT_TYPE_'

  # Extract/process common fields
  class_methods do
    # The :process key lives in different places for different events
    def build_json_paths(process_path)
      computed_signing_info_path = process_path + ".'signing info (computed)'"

      # Keys are columns we want to extract, values are JSONPath locations of the data
      json_paths = {
        event_type: '$.event',
        event_timestamp: '$.timestamp',
        process_name: process_path + '.name',
        process_arguments: process_path + '.arguments',
        reported_signing_id: process_path + ".'signing info (reported)'.signingID",
        computed_signing_id: computed_signing_info_path + '.signatureID',
        signature_signer: computed_signing_info_path + '.signatureSigner',
        signature_authorities: computed_signing_info_path + '.signatureAuthorities'
      }

      %w(uid pid ppid rpid).each do |process_col|
        json_paths.merge!(process_col.to_sym => process_path + '.' + process_col)
      end

      json_paths
    end

    def extract_attributes_from_json(json)
      begin
        row = json_paths.inject({ raw_event: JSON.parse(json) }) do |row, (col_name, jsonpath)|
          # TODO: reparsing for every column is stupid; just use dig()
          row[col_name] = JsonPath.on(json, jsonpath)[0]
          row
        end
      rescue MultiJson::ParseError => e
        Rails.logger.error("#{e.class.to_s} while parsing. Message: #{e.message}. Attempting to continue.\nBroken JSON: #{json}")
        return nil
      end

      row[:event_type].delete_prefix!(ES_EVENT_TYPE_PREFIX)
      row[:is_process_signed_as_reported] = (row[:computed_signing_id] == row[:reported_signing_id])
      row.delete(:reported_signing_id) if row[:is_process_signed_as_reported]

      if row[:computed_signing_id].nil? || !row[:is_process_signed_as_reported]
        pretty_json = JSON.pretty_generate(row[:raw_event])
        Rails.logger.warn("No signature or mismatched signer for process:\n\nROW: #{row}\n\nJSON #{pretty_json}")
      end

      if row.has_key?(:process_arguments)
        if row[:process_arguments].blank?
          row[:process_arguments] = nil
        else
          row[:process_arguments] = row[:process_arguments].join(' ')
        end
      end

      row
    end

    def new_from_json(json)
      new(extract_attributes_from_json(json))
    end

    # To be overloaded by subclasses - usually just SHARED_JSON_PATHS with a few other fields.
    def json_paths
      raise NotImplementedError
    end
  end
end
