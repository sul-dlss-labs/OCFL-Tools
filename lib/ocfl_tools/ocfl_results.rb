module OcflTools
  # Dedicated class for collating results of validation and verification checks
  # performed by objects. Designed to replace the spaggy @my_results in various places.
  class OcflResults
    def initialize
      @my_results             = {}
      @my_results['error']    = {}
      @my_results['warn']     = {}
      @my_results['info']     = {}
      @my_results['ok']       = {}

      @my_contexts            = {}

    end

    def results
      @my_results
    end

    def all
      @my_results
    end

    def get_errors
      @my_results['error']
    end

    def get_warnings
      @my_results['warn']
    end

    def get_info
      @my_results['info']
    end

    def get_ok
      @my_results['ok']
    end

    # Processes all of @my_results and creates a nested hash of
    # context => level => code => [ descriptions ]
    # Useful if you want to get all the info/error/warn/ok results for a specific context.
    def get_contexts
      @my_results.each do | level, codes | # levels are warn, info, ok, error
        codes.each do | code, contexts |
          contexts.each do | context, description |
            #puts "got  : #{level} #{code} #{context} #{description}"
            #puts "want : #{context} #{level} #{code} #{description}"
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
              @my_contexts[context] = Hash.new
              my_level = Hash.new
              my_level[code] = description
              @my_contexts[context] = { level => my_level }
            end
          end
        end
      end
      return @my_contexts
    end

    # Get all results for a specific context (e.g. 'verify_checksums')
    def get_context(my_context)
      self.get_contexts[my_context]
    end

    # @return [Integer] error_count of errors in results.
    def error_count
      my_count = 0
      @my_results['error'].each do | code, contexts |
        contexts.each do | context, description |
          my_count = my_count + description.size
        end
      end
      my_count
    end

    def warn_count
      my_count = 0
      @my_results['warn'].each do | code, contexts |
        contexts.each do | context, description |
          my_count = my_count + description.size
        end
      end
      my_count
    end

    def info_count
      my_count = 0
      @my_results['info'].each do | code, contexts |
        contexts.each do | context, description |
          my_count = my_count + description.size
        end
      end
      my_count
    end

    def ok_count
      my_count = 0
      @my_results['ok'].each do | code, contexts |
        contexts.each do | context, description |
          my_count = my_count + description.size
        end
      end
      my_count
    end

    # @returns [String] description of posted OK statement.
    def ok(code, context, description)
      if @my_results['ok'].key?(code) == false
        @my_results['ok'][code] = Hash.new
      end
      if @my_results['ok'][code].key?(context) == false
        @my_results['ok'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['ok'][code][context].include?(description)
          return description
        else
          @my_results['ok'][code][context] = ( @my_results['ok'][code][context] << description )
      end
    end

    # @returns [String] description of posted information.
    def info(code, context, description)
      if @my_results['info'].key?(code) == false
        @my_results['info'][code] = Hash.new
      end
      if @my_results['info'][code].key?(context) == false
        @my_results['info'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['info'][code][context].include?(description)
          return description
        else
          @my_results['info'][code][context] = ( @my_results['info'][code][context] << description )
      end
    end

    # @returns [String] description of posted warning.
    def warn(code, context, description)
      if @my_results['warn'].key?(code) == false
        @my_results['warn'][code] = Hash.new
      end
      if @my_results['warn'][code].key?(context) == false
        @my_results['warn'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['warn'][code][context].include?(description)
          return description
        else
          @my_results['warn'][code][context] = ( @my_results['warn'][code][context] << description )
      end
    end

    # @returns [String] description of posted error.
    def error(code, context, description)
      if @my_results['error'].key?(code) == false
        @my_results['error'][code] = Hash.new
      end
      if @my_results['error'][code].key?(context) == false
        @my_results['error'][code][context] = []
      end
      # Only put unique values into description
      if @my_results['error'][code][context].include?(description)
          return description
        else
          @my_results['error'][code][context] = ( @my_results['error'][code][context] << description )
      end
    end

  end
end
