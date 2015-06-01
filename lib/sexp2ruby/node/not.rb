module Sexp2Ruby
  module Node
    class Not < Base
      def to_s(exp)
        "(not #{process exp.shift})"
      end
    end
  end
end
