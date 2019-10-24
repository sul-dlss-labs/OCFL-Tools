module OcflTools
  # Class to take new content from a deposit directory and marshal it
  # into a new version directory of a new or existing OCFL object dir.
  # Expects deposit_dir to be:
  # <ocfl deposit directoy>/
  #     |-- inventory.json (from object_directory root)
  #     |-- head/
  #         |-- manifest.json (all proposed file actions)
  #         |-- <content_dir>/
  #             |-- <files to add or modify>
  #
  class OcflDeposit < OcflTools::OcflInventory
    def initialize(deposit_directory, object_directory)
    end
  end
end
