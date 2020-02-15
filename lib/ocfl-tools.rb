# frozen_string_literal: true

# OcflTools is a module that provides a distintive namespace for classes that create,
# maintain and read Oxford Common File Layout preservation objects.
#
# ====Data Model
#
# * <b>{OcflObject} = an object that models the internal data structures of an OCFL manifest.</b>
#   * {OcflInventory} = An I/O interface for {OcflObject} allowing the reading and creaton of OCFL inventory.json files.
#
# @note Copyright (c) 2019 by The Board of Trustees of the Leland Stanford Junior University.

require 'ocfl_tools'
require 'json'
require 'anyway'
require 'fileutils'
require 'digest'
require 'time' # for iso8601 checking.
