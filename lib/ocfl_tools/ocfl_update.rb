module OcflTools
  class OcflUpdate < OcflTools::OcflInventory
    # Needs to be given the full filepath to the object.
    # can compare the current inventory.json with detected version dirs.

    attr_accessor :object_directory

    def initialize(object_directory)
      @object_directory = object_directory # We may not need this; handled by the next level up?
    end

    # If you wanted to slurp in an existing inventory and mess with a prior version,
    # and try to have State transfer correctly to future versions, this is the place for you.
    # Except I've not implemented it yet, because it's kinda against spec.
    
  end
end
