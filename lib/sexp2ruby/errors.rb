module Sexp2Ruby

  # Raised when `Processor` is initialized with an unknown
  # option, or a known option with an invalid value.
  class InvalidOption < StandardError
  end
end
