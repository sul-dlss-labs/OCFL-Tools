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
      # return warnings only
      @my_results['warn']
    end

    def get_info
      @my_results['info']
    end

    def get_ok
      @my_results['ok']
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
