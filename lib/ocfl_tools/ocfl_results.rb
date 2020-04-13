# frozen_string_literal: true

module OcflTools
  # Class for collating results of validation and verification checks.
  class OcflResults
    def initialize
      @my_results             = {}
      @my_results['error']    = {}
      @my_results['warn']     = {}
      @my_results['info']     = {}
      @my_results['ok']       = {}

      @my_contexts = {}
    end

    # Convenience method for obtaining a hash  of results.
    # @return [Hash] of results stored in this instance.
    def results
      @my_results
    end

    # Convenience method for obtaining a hash  of results.
    # @return [Hash] of results stored in this instance.
    def all
      @my_results
    end

    # Convenience method to print out the results hash to stdout.
    def print
      @my_results.each do | level, status_codes |
        puts "#{level.upcase}" unless status_codes.size == 0
        status_codes.each do | code, contexts |
          contexts.each do | context, descriptions |
            descriptions.each do | desc |
              puts "  #{code}:#{context}:#{desc}"
            end
          end
        end
      end
    end

    # @return [Hash] a hash of all the 'error' entries stored in this instance.
    def get_errors
      @my_results['error']
    end

    # @return [Hash] a hash of all the 'warn' entries stored in this instance.
    def get_warnings
      @my_results['warn']
    end

    # @return [Hash] a hash of all the 'info' entries stored in this instance.
    def get_info
      @my_results['info']
    end

    # @return [Hash] a hash of all the 'OK' entries stored in this instance.
    def get_ok
      @my_results['ok']
    end

    # Convenience method to look up offical OCFL validation codes.
    # @param [String] code a 4-character string starting of E, W or I and 3 digits.
    # @return [Hash] a hash describing the requested OCFL validation code.
    def get_code(code)
      upcode = code.upcase # just in case you forget; no harm, no foul.
      case
      when upcode =~ /^E\d{3}$/
        get_error_code(upcode)
      when upcode =~/^W\d{3}$/
        get_warning_code(upcode)
      when upcode =~/^I\d{3}$/
        get_information_code(upcode)
      else
        raise OcflTools::Errors::SyntaxError, "#{code} is not a valid OCFL error, warn or info code."
      end
    end

    # Processes all of @my_results and creates a nested hash of
    # context => level => code => [ descriptions ]
    # Useful if you want to get all the info/error/warn/ok results for a specific context.
    # @return [Hash] a nested hash of results, organized with 'context' as a top level key.
    def get_contexts
      @my_results.each do |level, codes| # levels are warn, info, ok, error
        codes.each do |code, contexts|
          contexts.each do |context, description|
            # puts "got  : #{level} #{code} #{context} #{description}"
            # puts "want : #{context} #{level} #{code} #{description}"
            if @my_contexts.key?(context)
              my_levels = @my_contexts[context]
              if my_levels.key?(level)
                my_codes = my_levels[level]
                if my_codes.key?(code)
                  # what should I do here? Nothing, apparently, as it's soft-copied already.
                else
                  my_codes[code] = description # new code for this level! Add it.
                end
              else
                # if the context key already exists, but the level key
                # does not, we can add everything beneath context in one go.
                my_levels[level] = { code => description }
              end
            else
              # If the context (the top level key) doesn't exist already,
              # we can just slam everything in at once.
              @my_contexts[context] = {}
              my_level = {}
              my_level[code] = description
              @my_contexts[context] = { level => my_level }
            end
          end
        end
      end
      @my_contexts
    end

    # Get all results for a specific context (e.g. 'verify_checksums')
    # @param [String] my_context a string value of the context (e.g. 'verify_checksums') to query
    # @return [Hash] a hash of results for the specified context, arranged by 'code' => [ descriptions ].
    def get_context(my_context)
      get_contexts[my_context]
    end

    # Gets the total number of error events contained within this instance.
    # @return [Integer] the number of errors.
    def error_count
      my_count = 0
      @my_results['error'].each do |_code, contexts|
        contexts.each do |_context, description|
          my_count += description.size
        end
      end
      my_count
    end

    # Gets the total number of warning events contained within this instance.
    # @return [Integer] the number of warnings.
    def warn_count
      my_count = 0
      @my_results['warn'].each do |_code, contexts|
        contexts.each do |_context, description|
          my_count += description.size
        end
      end
      my_count
    end

    # Gets the total number of 'info' events contained within this instance.
    # @return [Integer] the number of informational messages.
    def info_count
      my_count = 0
      @my_results['info'].each do |_code, contexts|
        contexts.each do |_context, description|
          my_count += description.size
        end
      end
      my_count
    end

    # Gets the total number of 'ok' events contained within this instance.
    # @return [Integer] the number of OK messages.
    def ok_count
      my_count = 0
      @my_results['ok'].each do |_code, contexts|
        contexts.each do |_context, description|
          my_count += description.size
        end
      end
      my_count
    end

    # Creates an 'OK' message in the object with the specified code and context.
    # @param [String] code the appropriate 'ok' code for this event.
    # @param [String] context the process or class that is creating this event.
    # @param [String] description the details of this specific event.
    # @return [String] description of posted OK statement.
    def ok(code, context, description)
      @my_results['ok'][code] = {} if @my_results['ok'].key?(code) == false
      if @my_results['ok'][code].key?(context) == false
        @my_results['ok'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['ok'][code][context].include?(description)
        return description
      else
        @my_results['ok'][code][context] = (@my_results['ok'][code][context] << description)
      end
    end

    # Creates an 'info' message in the object with the specified code and context.
    # @param [String] code the appropriate 'Info' code for this event.
    # @param [String] context the process or class that is creating this event.
    # @param [String] description the details of this specific event.
    # @return [String] description of posted Info statement.
    def info(code, context, description)
      @my_results['info'][code] = {} if @my_results['info'].key?(code) == false
      if @my_results['info'][code].key?(context) == false
        @my_results['info'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['info'][code][context].include?(description)
        return description
      else
        @my_results['info'][code][context] = (@my_results['info'][code][context] << description)
      end
    end

    # Creates a 'Warn' message in the object with the specified code and context.
    # @param [String] code the appropriate 'warn' code for this event.
    # @param [String] context the process or class that is creating this event.
    # @param [String] description the details of this specific event.
    # @return [String] description of posted Warn statement.
    def warn(code, context, description)
      @my_results['warn'][code] = {} if @my_results['warn'].key?(code) == false
      if @my_results['warn'][code].key?(context) == false
        @my_results['warn'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['warn'][code][context].include?(description)
        return description
      else
        @my_results['warn'][code][context] = (@my_results['warn'][code][context] << description)
      end
    end

    # Creates an 'Error' message in the object with the specified code and context.
    # @param [String] code the appropriate 'error' code for this event.
    # @param [String] context the process or class that is creating this event.
    # @param [String] description the details of this specific event.
    # @return [String] description of posted Error statement.
    def error(code, context, description)
      if @my_results['error'].key?(code) == false
        @my_results['error'][code] = {}
      end
      if @my_results['error'][code].key?(context) == false
        @my_results['error'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['error'][code][context].include?(description)
        return description
      else
        @my_results['error'][code][context] = (@my_results['error'][code][context] << description)
      end
    end

    # Given another {OcflTools::OcflResults} instance, copy that object's data into this one. Used to 'roll up' Results
    # from different levels of validation or process into a single results instance.
    # @param {OcflTools::OcflResults} source Results instance to copy into this instance.
    # @return {OcflTools::OcflResults} self
    def add_results(source)
      unless source.is_a?(OcflTools::OcflResults)
        raise "#{source} is not a Results object!"
      end

      source.get_ok.each do |code, contexts|
        contexts.each do |context, descriptions|
          descriptions.each do |description|
            ok(code, context, description)
          end
        end
      end

      source.get_info.each do |code, contexts|
        contexts.each do |context, descriptions|
          descriptions.each do |description|
            info(code, context, description)
          end
        end
      end

      source.get_warnings.each do |code, contexts|
        contexts.each do |context, descriptions|
          descriptions.each do |description|
            warn(code, context, description)
          end
        end
      end

      source.get_errors.each do |code, contexts|
        contexts.each do |context, descriptions|
          descriptions.each do |description|
            error(code, context, description)
          end
        end
      end
      self
    end

    private

    def get_error_code(code)
      OcflTools::Errors::ValidationError.code(code)
      rescue OcflTools::Errors::SyntaxError => e
      # Code not found; just re-raise it for now.
        raise
    end

    def get_warning_code(code)
      puts "This is a dummy method for now."
      rescue OcflTools::Errors::SyntaxError => e
      # Code not found; just re-raise it for now.
        raise
    end

    def get_information_code(code)
      puts "Yet more dummy code for infos."
      rescue OcflTools::Errors::SyntaxError => e
      # Code not found; just re-raise it for now.
        raise
    end

  end
end
