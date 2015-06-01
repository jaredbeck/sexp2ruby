module Sexp2Ruby
  module Node
    class Dot2 < Base
      def to_s(exp)
        "(#{process exp.shift}..#{process exp.shift})"
      end
    end
  end
end
