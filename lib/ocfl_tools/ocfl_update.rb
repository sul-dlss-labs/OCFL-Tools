module OcflTools
  class OcflUpdate < OcflTools::OcflInventory
    # Needs to be given the full filepath to the object.
    # can compare the current inventory.json with detected version dirs.

    attr_accessor :object_directory

    def initialize(object_directory)
      @object_directory = object_directory # We may not need this; handled by the next level up?
    end

    # need to get most recent version inventory,
    # and support delta operations on it (add, del, rename actions)
    # May also have to compute digests for the new files.

    # Get most recent state from inventory
    # be given digest of file & filename to change
    # Given existing digest & existing filename == delete.
    # Given existing digest & new filename == copy
    # Given new digest & new filename == add
    # Given new digest & existing filename == modify/update
    # Will need a list of all existing filenames in state.
    #
    # Import the existing inventory.
    # Stage the changes for the new version.
    # Write out the new inventory.

    # Get Head version.
    # Add new version (copy state from prior version).
    # build out new state & manifest block.
    # - new and modified files need manifest entries.
    # - deletes, copies and re-names need edits to new state block.

    # Moved all the primitives down to OCFLObject.
    # OcflUpdate should operate on lists of files to change.

  end
end
