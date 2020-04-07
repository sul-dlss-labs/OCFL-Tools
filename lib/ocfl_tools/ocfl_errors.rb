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
        'E021' => {
          :desc => 'If the key contentDirectory is not present in the inventory file then the name of the designated content sub-directory must be content.',
          :link => 'https://ocfl.io/draft/spec/#E021'
        },
        # The Moab Exception.
        'E022' => {
          :desc => 'OCFL-compliant tools (including any validators) must ignore all directories in the object version directory except for the designated content directory.',
          :link => 'https://ocfl.io/draft/spec/#E022'
        },
        'E023' => {
          :desc => 'Every file within a version\'s content directory must be referenced in the manifest section of the inventory.',
          :link => 'https://ocfl.io/draft/spec/#E023'
        },
        'E024' => {
          :desc => 'There must not be empty directories within a version\'s content directory.',
          :link => 'https://ocfl.io/draft/spec/#E024'
        },
        'E025' => {
          :desc => 'For content-addressing, OCFL Objects must use either sha512 or sha256, and should use sha512.',
          :link => 'https://ocfl.io/draft/spec/#E025'
        },
        'E026' => {
          :desc => 'For storage of additional fixity values, or to support legacy content migration, implementers must choose from the following controlled vocabulary of digest algorithms, or from a list of additional algorithms given in the [Digest-Algorithms-Extension].',
          :link => 'https://ocfl.io/draft/spec/#E026'
        },
        'E027' => {
          :desc => 'OCFL clients must support all fixity algorithms given in the table below, and may support additional algorithms from the extensions.',
          :link => 'https://ocfl.io/draft/spec/#E027'
        },
        'E028' => {
          :desc => 'Optional fixity algorithms that are not supported by a client must be ignored by that client.',
          :link => 'https://ocfl.io/draft/spec/#E028'
        },
        # If you use SHA1 in the fixity block...
        'E029' => {
          :desc => 'SHA-1 algorithm defined by [FIPS-180-4] and must be encoded using hex (base16) encoding [RFC4648].',
          :link => 'https://ocfl.io/draft/spec/#E029'
        },
        # Only mentioned in the context of fixity, but presumably also applies to Digest choice.
        'E030' => {
          :desc => 'SHA-256 algorithm defined by [FIPS-180-4] and must be encoded using hex (base16) encoding [RFC4648].',
          :link => 'https://ocfl.io/draft/spec/#E030'
        },
        # As E030; presumably also applies to Digest value.
        'E031' => {
          :desc => 'SHA-512 algorithm defined by [FIPS-180-4] and must be encoded using hex (base16) encoding [RFC4648].',
          :link => 'https://ocfl.io/draft/spec/#E031'
        },
        'E032' => {
          :desc => '[blake2b-512] must be encoded using hex (base16) encoding [RFC4648].',
          :link => 'https://ocfl.io/draft/spec/#E032'
        },
        # Inventory must be JSON, must adhere to structure defined here.
        'E033' => {
          :desc => 'An OCFL Object Inventory MUST follow the [JSON] structure described in this section and must be named inventory.json.',
          :link => 'https://ocfl.io/draft/spec/#E033'
        },
        # Inventory file must be called 'inventory.json'. This will be hard to test.
        'E034' => {
          :desc => 'An OCFL Object Inventory must follow the [JSON] structure described in this section and MUST be named inventory.json.',
          :link => 'https://ocfl.io/draft/spec/#E034'
        },
        # Another hard one to test; how do we know that non-/ characters might be path separators?
        'E035' => {
          :desc => 'The forward slash (/) path separator must be used in content paths in the manifest and fixity blocks within the inventory.',
          :link => 'https://ocfl.io/draft/spec/#E035'
        },
        'E036' => {
          :desc => 'An OCFL Object Inventory must include the following keys: [id, type, digestAlgorithm, head]',
          :link => 'https://ocfl.io/draft/spec/#E036'
        },
        'E037' => {
          :desc => '[id] must be unique in the local context, and should be a URI [RFC3986].',
          :link => 'https://ocfl.io/draft/spec/#E037'
        },
        'E038' => {
          :desc => '[type] must be the URI of the inventory section of the specification, https://ocfl.io/1.0/spec/#inventory.',
          :link => 'https://ocfl.io/draft/spec/#E038'
        },
        'E039' => {
          :desc => '[digestAlgorithm] must be either sha512 or sha256, and should be sha512.',
          :link => 'https://ocfl.io/draft/spec/#E039'
        },
        'E040' => {
          :desc => '[head] must be the version directory name with the highest version number.',
          :link => 'https://ocfl.io/draft/spec/#E040'
        },
        'E041' => {
          :desc => 'In addition to these keys, there must be two other blocks present, manifest and versions, which are discussed in the next two sections.',
          :link => 'https://ocfl.io/draft/spec/#E041'
        },
        'E042' => {
          :desc => 'Content paths within a manifest block must be relative to the OCFL Object Root.',
          :link => 'https://ocfl.io/draft/spec/#E042'
        },
        # There must be 'a block for storing versions', which isn't terribly actionable.
        'E043' => {
          :desc => 'An OCFL Object Inventory must include a block for storing versions.',
          :link => 'https://ocfl.io/draft/spec/#E043'
        },
        # There must be a Versions key in inventory.json.
        'E044' => {
          :desc => 'This block MUST have the key of versions within the inventory, and it must be a JSON object.',
          :link => 'https://ocfl.io/draft/spec/#E044'
        },
        # The contents of the Versions key must be a JSON object (not a single value)
        'E045' => {
          :desc => 'This block must have the key of versions within the inventory, and it MUST be a JSON object.',
          :link => 'https://ocfl.io/draft/spec/#E045'
        },
        # v1, v2, etc as discovered on disk or from Manifest block content path.
        'E046' => {
          :desc => 'The keys of [the versions object] must correspond to the names of the version directories used.',
          :link => 'https://ocfl.io/draft/spec/#E046'
        },
        # Versions key values must be JSON objects that conform to  3.5.3.1.
        'E047' => {
          :desc => 'Each value [of the versions object] must be another JSON object that characterizes the version, as described in the 3.5.3.1 Version section.',
          :link => 'https://ocfl.io/draft/spec/#E047'
        },
        'E048' => {
          :desc => 'A JSON object to describe one OCFL Version, which must include the following keys: [created, state, message, user]',
          :link => 'https://ocfl.io/draft/spec/#E048'
        },
        'E049' => {
          :desc => '[the value of the "created" key] must be expressed in the Internet Date/Time Format defined by [RFC3339].',
          :link => 'https://ocfl.io/draft/spec/#E049'
        },
        'E050' => {
          :desc => 'The keys of [the "state" JSON object] are digest values, each of which must correspond to an entry in the manifest of the inventory.',
          :link => 'https://ocfl.io/draft/spec/#E050'
        },
        'E051' => {
          :desc => 'The logical path [value of a "state" digest key] must be interpreted as a set of one or more path elements joined by a / path separator.',
          :link => 'https://ocfl.io/draft/spec/#E051'
        },
        'E052' => {
          :desc => '[logical] Path elements must not be ., .., or empty (//).',
          :link => 'https://ocfl.io/draft/spec/#E052'
        },
        'E053' => {
          :desc => 'Additionally, a logical path must not begin or end with a forward slash (/).',
          :link => 'https://ocfl.io/draft/spec/#E053'
        },
        'E054' => {
          :desc => 'The value of the user key must contain a user name key, "name" and should contain an address key, "address".',
          :link => 'https://ocfl.io/draft/spec/#E054'
        },
        # IF a fixity block exists, it must be a top-level key called 'fixity'
        'E055' => {
          :desc => 'This block must have the key of fixity within the inventory.',
          :link => 'https://ocfl.io/draft/spec/#E055'
        },
        # IF fixity block exists, it can only contain keys defined in the controlled vocab OR via extension.
        'E056' => {
          :desc => 'The fixity block must contain keys corresponding to the controlled vocabulary given in the digest algorithms listed in the Digests section, or in a table given in an Extension.',
          :link => 'https://ocfl.io/draft/spec/#E056'
        },
        # IF fixity block exists, it should be digest => [Array of content paths]
        'E057' => {
          :desc => 'The value of the fixity block for a particular digest algorithm must follow the structure of the manifest block; that is, a key corresponding to the digest value, and an array of content paths that match that digest.',
          :link => 'https://ocfl.io/draft/spec/#E057'
        },
        # inventory digest sidecars MUST exist.
        'E058' => {
          :desc => 'Every occurrence of an inventory file must have an accompanying sidecar file stating its digest.',
          :link => 'https://ocfl.io/draft/spec/#E058'
        },
        # TBD; E092 missing from spec.
        'E092' => {
          :desc => 'This sidecar file must be of the form inventory.json.ALGORITHM, where ALGORITHM is the chosen digest algorithm for the object.',
          :link => 'https://ocfl.io/draft/spec/#E092'
        },
        'E059' => {
          :desc => 'This value must match the value given for the digestAlgorithm key in the inventory.',
          :link => 'https://ocfl.io/draft/spec/#E059'
        },
        'E060' => {
          :desc => 'The digest sidecar file must contain the digest of the inventory file.',
          :link => 'https://ocfl.io/draft/spec/#E060'
        },
        'E061' => {
          :desc => '[The digest sidecar file] must follow the format: DIGEST inventory.json',
          :link => 'https://ocfl.io/draft/spec/#E061'
        },
        'E062' => {
          :desc => 'The digest of the inventory must be computed only after all changes to the inventory have been made, and thus writing the digest sidecar file is the last step in the versioning process.',
          :link => 'https://ocfl.io/draft/spec/#E062'
        },
        'E063' => {
          :desc => 'Every OCFL Object must have an inventory file within the OCFL Object Root, corresponding to the state of the OCFL Object at the current version.',
          :link => 'https://ocfl.io/draft/spec/#E063'
        },
        'E064' => {
          :desc => 'Where an OCFL Object contains inventory.json in version directories, the inventory file in the OCFL Object Root must be the same as the file in the most recent version.',
          :link => 'https://ocfl.io/draft/spec/#E064'
        },
        # Dupe of E058
        'E065' => {
          :desc => 'Every inventory file must have a corresponding Inventory Digest.',
          :link => 'https://ocfl.io/draft/spec/#E065'
        },
        'E066' => {
          :desc => 'Each version block in each prior inventory file must represent the same object state as the corresponding version block in the current inventory file.',
          :link => 'https://ocfl.io/draft/spec/#E066'
        },
        'E067' => {
          :desc => 'The extensions directory must not contain any files, and no sub-directories other than extension sub-directories.',
          :link => 'https://ocfl.io/draft/spec/#E067'
        },
        'E068' => {
          :desc => 'The specific structure and function of the extension, as well as a declaration of the registered extension name must be defined in one of the following locations: The OCFL Extensions repository OR The Storage Root, as a plain text document directly in the Storage Root.',
          :link => 'https://ocfl.io/draft/spec/#E068'
        }
        # E069+ are storage root errors, out of scope for this validator for now.
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
