# frozen_string_literal: true

# Our interface to the DFC Connector library.
module DfcIo
  # Serialise DFC Connector subjects as JSON-LD string.
  def self.export(*subjects)
    return "" if subjects.empty?

    DfcLoader.connector.export(*subjects)
  end

  # Parse JSON-LD into an Array of DFC Connector subjects.
  #
  # The DFC Connector returns a single subject when the JSON-LD contains only
  # one and an Array otherwise. Nested typed nodes like a Price count as
  # subjects. We always return an Array to keep the result predictable.
  def self.import(json_string_or_io)
    Array.wrap(DfcLoader.connector.import(json_string_or_io))
  end
end
