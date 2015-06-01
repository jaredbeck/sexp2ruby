module Sexp2Ruby
  module Node
    class Dot3 < Base
      def to_s(exp)
        "(#{process exp.shift}...#{process exp.shift})"
      end
    end
  end
end
