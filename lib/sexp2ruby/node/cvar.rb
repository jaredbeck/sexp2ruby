module Sexp2Ruby
  module Node
    class Cvar < Base
      def to_s(exp)
        "#{exp.shift}"
      end
    end
  end
end
