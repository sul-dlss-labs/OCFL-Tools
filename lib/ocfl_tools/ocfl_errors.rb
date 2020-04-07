module OcflTools
  module Errors
    # See this for a nice model.
    # https://github.com/ryanb/cancan/blob/master/lib/cancan/exceptions.rb
    class ValidationError < StandardError
      attr_accessor :details
      attr_accessor :msg
      def initialize(msg: "A validation error has occured.", details: {} )
        @msg = msg
        @details = details
      end
    end

    # For bad client requests
    class ClientError < StandardError; end

    class SyntaxError < StandardError
      def initialize(msg="Generic syntax error.")
      end
    end

    class UnableToLoadInventoryFile < StandardError
      def initialize(msg="Requested inventory file failed to load. See downstream errors for details.")
      end
    end

    ### Client errors (you asked for the wrong stuff)
    class RequestedKeyNotFound < ClientError
      # You ask for key 'foo', but you are dumb and key 'foo' is not in the spec.
      def initialize(msg="Requested key not found in provided inventory.json.")
      end
    end

    class RequestedFileNotFound < ClientError
      def initialize(msg="Requested file does not exist.")
      end
    end

    class RequestedDirectoryNotFound < ClientError
      def initialize(msg="Requested directory does not exist.")
      end
    end

    class FileMissingFromVersionState < ClientError
      def initialize(msg="The requested file cannot be found in the provided version state block.")
      end
    end

    class FileDigestMismatch < ClientError
      def initialize(msg="The requested file already exists in inventory with different digest.")
      end
    end

    # You asked for version -1, or version 44c.
    class NonCompliantValue < ClientError
      def initialize(msg="Value provided is outside of specification bounds.")
      end
    end

    ### Validation errors (stuff that MUST be true, per spec, is not)
    class RequiredKeyNotFound < ValidationError
      # key 'foo' is in the spec and should be in the inventory. Fail if not.
      def initialize(msg="Required key not found in provided inventory.json.")
      end
    end

    class CannotEditPreviousVersion < ValidationError
      def initialize(msg="Previous version state blocks are considered read-only.")
      end
    end

  end
end
