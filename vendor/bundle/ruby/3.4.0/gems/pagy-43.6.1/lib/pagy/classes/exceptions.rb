# frozen_string_literal: true

class Pagy
  # Specific subclass of ArgumentError
  class OptionError < ArgumentError
    attr_reader :pagy, :option, :value

    # Prepare a useful feedback
    def initialize(pagy, option, description, value)
      @pagy   = pagy
      @option = option
      @value  = value

      super("expected :#{@option} #{description}; got #{@value.inspect}")
    end
  end

  # Specific subclass of OptionError
  class RangeError < OptionError; end

  # I18n localization error
  class RailsI18nLoadError < LoadError; end

  # Generic internal error
  class InternalError < StandardError; end
end
