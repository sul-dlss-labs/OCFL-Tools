module OcflTools
  module Errors
    # See this for a nice model.
    # https://github.com/ryanb/cancan/blob/master/lib/cancan/exceptions.rb
    class ValidationError < StandardError
      attr_accessor :details
      attr_accessor :msg

      ERROR_CODE = {
        'E001' => {
          :desc => 'The OCFL Object Root must not contain files or directories other than those specified in the following sections.',
          :link => 'https://ocfl.io/draft/spec/#E001'
        },
        # Raise E002 if E004 is true.
        'E002' => {
          :desc => 'The version declaration must be formatted according to the NAMASTE specification.',
          :link => 'https://ocfl.io/draft/spec/#E002'
        },
        'E003' => {
          :desc => '[The version declaration] must be a file in the base directory of the OCFL Object Root giving the OCFL version in the filename.',
          :link => 'https://ocfl.io/draft/spec/#E003'
        },
        # Raise E004 if either E005 or E006 is true.
        'E004' => {
          :desc => 'The [version declaration] filename MUST conform to the pattern T=dvalue, where T must be 0, and dvalue must be ocfl_object_, followed by the OCFL specification version number.',
          :link => 'https://ocfl.io/draft/spec/#E004'
        },
        # T != 0
        'E005' => {
          :desc => 'The [version declaration] filename must conform to the pattern T=dvalue, where T MUST be 0, and dvalue must be ocfl_object_, followed by the OCFL specification version number.',
          :link => 'https://ocfl.io/draft/spec/#E005'
        },
        # dvalue != ocfl_object_1
        'E006' => {
          :desc => 'The [version declaration] filename must conform to the pattern T=dvalue, where T must be 0, and dvalue MUST be ocfl_object_, followed by the OCFL specification version number.',
          :link => 'https://ocfl.io/draft/spec/#E006'
        },
        'E007' => {
          :desc => 'The text contents of the [version declaration] file must be the same as dvalue, followed by a newline (\n).',
          :link => 'https://ocfl.io/draft/spec/#E007'
        },
        'E008' => {
          :desc => 'OCFL Object content must be stored as a sequence of one or more versions.',
          :link => 'https://ocfl.io/draft/spec/#E008'
        },
        # Version numbers must start at 1
        'E009' => {
          :desc => 'The version number sequence MUST start at 1 and must be continuous without missing integers.',
          :link => 'https://ocfl.io/draft/spec/#E009'
        },
        # Version numbers must be continous without missing integers.
        'E010' => {
          :desc => 'The version number sequence must start at 1 and MUST be continuous without missing integers.',
          :link => 'https://ocfl.io/draft/spec/#E010'
        },
        'E011' => {
          :desc => 'If zero-padded version directory numbers are used then they must start with the prefix v and then a zero.',
          :link => 'https://ocfl.io/draft/spec/#E011'
        },
        'E012' => {
          :desc => 'All version directories of an object must use the same naming convention: either a non-padded version directory number, or a zero-padded version directory number of consistent length.',
          :link => 'https://ocfl.io/draft/spec/#E012'
        },
        'E013' => {
          :desc => 'Operations that add a new version to an object must follow the version directory naming convention established by earlier versions.',
          :link => 'https://ocfl.io/draft/spec/#E013'
        },
        'E014' => {
          :desc => 'In all cases, references to files inside version directories from inventory files must use the actual version directory names.',
          :link => 'https://ocfl.io/draft/spec/#E014'
        },
        # Unexpected file(s) in version directory.
        'E015' => {
          :desc => 'There must be no other files as children of a version directory, other than an inventory file and a inventory digest.',
          :link => 'https://ocfl.io/draft/spec/#E015'
        },
        'E016' => {
          :desc => 'Version directories must contain a designated content sub-directory if the version contains files to be preserved, and should not contain this sub-directory otherwise.',
          :link => 'https://ocfl.io/draft/spec/#E016'
        },
        # No forward slash in contentDirectory
        'E017' => {
          :desc => 'The contentDirectory value MUST NOT contain the forward slash (/) path separator and must not be either one or two periods (. or ..).',
          :link => 'https://ocfl.io/draft/spec/#E017'
        },
        # contentDirectory cannot be . or ..
        'E018' => {
          :desc => 'The contentDirectory value must not contain the forward slash (/) path separator and MUST NOT be either one or two periods (. or ..).',
          :link => 'https://ocfl.io/draft/spec/#E018'
        },
        # v1 must have contentDirectory set, if it's set at all (can't set it for the first time in v2).
        'E019' => {
          :desc => 'If the key contentDirectory is set, it MUST be set in the first version of the object and must not change between versions of the same object.',
          :link => 'https://ocfl.io/draft/spec/#E019'
        },
        # contentDirectory value cannot change between versions.
        'E020' => {
          :desc => 'If the key contentDirectory is set, it must be set in the first version of the object and MUST NOT change between versions of the same object.',
          :link => 'https://ocfl.io/draft/spec/#E020'
        },
      }

      def initialize(msg: "A validation error has occured.", details: {} )
        @msg = msg
        @details = details
      end

      # Class method to lookup error code details
      def self.code(error_code)
        unless ERROR_CODE.key?(error_code)
          raise OcflTools::Errors::SyntaxError, "#{error_code} is not a valid OCFL validation errror."
        end
        ERROR_CODE[error_code]
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
