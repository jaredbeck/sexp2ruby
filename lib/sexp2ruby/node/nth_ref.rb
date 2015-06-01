module Sexp2Ruby
  module Node
    class NthRef < Base
      def to_s(exp)
        "$#{exp.shift}"
      end
    end
  end
end
