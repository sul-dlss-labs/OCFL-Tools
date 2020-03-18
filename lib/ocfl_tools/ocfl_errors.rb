module OcflTools
  module Errors

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
