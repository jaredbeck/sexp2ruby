module Sexp2Ruby
  module Node
    class Or < Base
      def to_s(exp)
        "(#{process exp.shift} or #{process exp.shift})"
      end
    end
  end
end
