module OcflTools
  module Errors

    class SyntaxError < StandardError
      def initialize(msg="Generic syntax error.")
        super
      end
    end

    class NonCompliantValue < StandardError
      def initialize(msg="Value provided is outside of specification bounds.")
        super
      end
    end

    class RequestedKeyNotFound < StandardError
      def initialize(msg="Requested key not found in provided inventory.json.")
        super
      end
    end

    class CannotEditPreviousVersion < StandardError
      def initialize(msg="Previous version state blocks are considered read-only.")
        super
      end
    end

    class FileMissingFromVersionState < StandardError
      def initialize(msg="The requested file cannot be found in the provided version state block.")
        super
      end
    end

    class Error211 < StandardError
      def initialize(msg="inventory.json is not valid JSON.")
        super
      end
    end

    class Error216 < StandardError
      def initialize(msg="Unable to find required key in inventory.json.")
        super
      end
    end

    class Error217 < StandardError
      def initialize(msg="Required key in inventory.json cannot be empty.")
        super
      end
    end

  end
end
